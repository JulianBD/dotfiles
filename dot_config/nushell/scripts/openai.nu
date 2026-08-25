# openai — the bits opencode zen does not proxy. Right now that means audio:
# zen serves no whisper/transcription models, so these talk to api.openai.com.
#
#   use openai.nu
#   openai transcribe recording.m4a
#   openai transcribe interview.mp3 --format srt | save interview.srt
#   ls *.m4a | each {|file| openai transcribe $file.name }
#
# Uploads go through `http upload` (see http.nu), which shells out to curl —
# nushell's native multipart cannot set a part filename, and OpenAI infers the
# audio container from it.

use ./http.nu

const BASE = "https://api.openai.com/v1"

# Resolve the OpenAI API key.
#
# $env.OPENAI_API_KEY wins, else `op read` of the reference in
# $env.OPENAI_API_KEY_OP.
#
# No output type annotation: the final expression is an `error make`, which
# nushell type-checks as an error rather than the declared string.
export def key [] {
    let from_environment = (http env-key "OPENAI_API_KEY")
    if $from_environment != null {
        return $from_environment
    }
    let op_reference = (http env-key "OPENAI_API_KEY_OP")
    if $op_reference != null {
        return (http op-key $op_reference)
    }
    error make {msg: "no openai key: set $env.OPENAI_API_KEY, or $env.OPENAI_API_KEY_OP to an op:// reference"}
}

# Reject response formats a transcription model cannot emit.
def check-format [
    model: string   # Transcription model id
    format: string  # Requested response format
] {
    let plain_only = ($model | str starts-with "gpt-4o")
    if $plain_only and $format not-in ["json" "text"] {
        error make {msg: $"($model) only supports json/text; use -m whisper-1 for ($format)"}
    }
}

# Upload audio to one of the /v1/audio routes and decode per response format.
def post-audio [
    route: string   # transcriptions | translations
    path: string    # Audio file to upload
    --fields: record = {}  # Extra form fields
    --format: string = "json"  # Requested response format
]: nothing -> any {
    # Checked here as well as in `http upload`: the header record below resolves
    # the API key eagerly, so without this a missing file reports "no openai key".
    let file = ($path | path expand --no-symlink)
    if not ($file | path exists) {
        let hint = if ($file | str contains "\\") {
            " (paths in quotes need no backslash escapes: use '3324 Beech Ave 4.m4a')"
        } else { "" }
        error make {msg: $"no such file: ($file)($hint)"}
    }

    let body = (
        http upload $"($BASE)/audio/($route)" $file
        --headers {Authorization: $"Bearer (key)"}
        --fields $fields
        --label "openai"
    )
    if $format in ["json" "verbose_json"] {
        let parsed = ($body | from json | http unwrap "openai")
        if $format == "json" { $parsed | get -o text | default $parsed } else { $parsed }
    } else {
        $body
    }
}

# Transcribe an audio file in its original language.
export def transcribe [
    path: string                        # Audio file (mp3, m4a, wav, webm, ...)
    --model (-m): string = "whisper-1"  # Or gpt-4o-transcribe, gpt-4o-mini-transcribe
    --format (-f): string = "json"      # json | text | srt | vtt | verbose_json
    --language (-l): string             # ISO-639-1 hint, e.g. en — improves accuracy
    --prompt (-p): string               # Spelling/context hint for proper nouns
    --temperature (-t): float           # Sampling temperature
]: nothing -> any {
    check-format $model $format
    let fields = (
        {model: $model, response_format: $format}
        | merge (if $language == null { {} } else { {language: $language} })
        | merge (if $prompt == null { {} } else { {prompt: $prompt} })
        | merge (if $temperature == null { {} } else { {temperature: $temperature} })
    )
    post-audio "transcriptions" $path --fields $fields --format $format
}

# Transcribe an audio file and translate it to English.
#
# The API supports whisper-1 only on this route.
export def translate [
    path: string                    # Audio file (mp3, m4a, wav, webm, ...)
    --format (-f): string = "json"  # json | text | srt | vtt | verbose_json
    --prompt (-p): string           # Spelling/context hint for proper nouns
    --temperature (-t): float       # Sampling temperature
]: nothing -> any {
    let fields = (
        {model: "whisper-1", response_format: $format}
        | merge (if $prompt == null { {} } else { {prompt: $prompt} })
        | merge (if $temperature == null { {} } else { {temperature: $temperature} })
    )
    post-audio "translations" $path --fields $fields --format $format
}
