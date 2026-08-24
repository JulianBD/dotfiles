# openai — the bits opencode zen does not proxy. Right now that means audio:
# zen serves no whisper/transcription models, so these talk to api.openai.com.
#
#   use openai.nu
#   openai transcribe recording.m4a
#   openai transcribe interview.mp3 --format srt | save interview.srt
#   ls *.m4a | each {|f| openai transcribe $f.name }
#
# Uploads go through `http upload` (see http.nu), which shells out to curl —
# nushell's native multipart cannot set a part filename, and OpenAI infers the
# audio container from it.

use ./http.nu

const BASE = "https://api.openai.com/v1"

# API key: $env.OPENAI_API_KEY, else `op read` of the ref in $env.OPENAI_API_KEY_OP.
export def key [] {
    let from_env = (http env-key "OPENAI_API_KEY")
    if $from_env != null {
        return $from_env
    }
    let op_ref = (http env-key "OPENAI_API_KEY_OP")
    if $op_ref != null {
        return (http op-key $op_ref)
    }
    error make {msg: "no openai key: set $env.OPENAI_API_KEY, or $env.OPENAI_API_KEY_OP to an op:// reference"}
}

# Formats each transcription model can emit.
def check-format [model: string, format: string] {
    let plain_only = ($model | str starts-with "gpt-4o")
    if $plain_only and $format not-in ["json" "text"] {
        error make {msg: $"($model) only supports json/text; use -m whisper-1 for ($format)"}
    }
}

def post-audio [route: string, path: string, fields: record, format: string] {
    # Checked here as well as in `http upload`: the header record below resolves
    # the API key eagerly, so without this a missing file reports "no openai key".
    let path = ($path | path expand --no-symlink)
    if not ($path | path exists) {
        let hint = (if ($path | str contains "\\") {
            " (paths in quotes need no backslash escapes: use '3324 Beech Ave 4.m4a')"
        } else { "" })
        error make {msg: $"no such file: ($path)($hint)"}
    }
    let out = (
        http upload $"($BASE)/audio/($route)" {Authorization: $"Bearer (key)"} $path $fields --label "openai"
    )
    if $format in ["json" "verbose_json"] {
        let parsed = ($out | from json | http unwrap "openai")
        if $format == "json" { $parsed | get -o text | default $parsed } else { $parsed }
    } else {
        $out
    }
}

# Transcribe an audio file in its original language.
export def transcribe [
    path: string                             # audio file (mp3, m4a, wav, webm, ...)
    --model (-m): string = "whisper-1"       # or gpt-4o-transcribe, gpt-4o-mini-transcribe
    --format (-f): string = "json"           # json | text | srt | vtt | verbose_json
    --language (-l): string                  # ISO-639-1 hint, e.g. en — improves accuracy
    --prompt (-p): string                    # spelling/context hint for proper nouns
    --temperature (-t): float
]: nothing -> any {
    check-format $model $format
    let fields = (
        {model: $model, response_format: $format}
        | merge (if $language == null { {} } else { {language: $language} })
        | merge (if $prompt == null { {} } else { {prompt: $prompt} })
        | merge (if $temperature == null { {} } else { {temperature: $temperature} })
    )
    post-audio "transcriptions" $path $fields $format
}

# Transcribe *and* translate to English. whisper-1 only, per the API.
export def translate [
    path: string
    --format (-f): string = "json"
    --prompt (-p): string
    --temperature (-t): float
]: nothing -> any {
    let fields = (
        {model: "whisper-1", response_format: $format}
        | merge (if $prompt == null { {} } else { {prompt: $prompt} })
        | merge (if $temperature == null { {} } else { {temperature: $temperature} })
    )
    post-audio "translations" $path $fields $format
}
