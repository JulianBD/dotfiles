# openai — the bits opencode zen does not proxy. Right now that means audio:
# zen serves no whisper/transcription models, so these talk to api.openai.com.
#
#   use openai.nu
#   openai transcribe recording.m4a
#   openai transcribe interview.mp3 --format srt | save interview.srt
#   openai transcribe detailed interview.mp3 | get segments
#   ls *.m4a | each {|file| openai transcribe $file.name }
#
# Uploads go through `http upload` (see http.nu), which shells out to curl —
# nushell's native multipart cannot set a part filename, and OpenAI infers the
# audio container from it.
#
# The text and record results are separate commands rather than one command
# with a --raw flag, so each carries a precise output type: `transcribe`
# always returns a string, `transcribe detailed` always returns a record.

use ./http.nu

const BASE = "https://api.openai.com/v1"

# Response formats that decode to a string.
const TEXT_FORMATS = ["json" "text" "srt" "vtt"]

# Transcription models zen does not serve.
const MODELS = ["whisper-1" "gpt-4o-transcribe" "gpt-4o-mini-transcribe"]

# Completer and validation source for --format.
def format-names []: nothing -> list<string> {
    $TEXT_FORMATS
}

# Completer for --model.
def model-names []: nothing -> list<string> {
    $MODELS
}

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

# Reject a response format the request cannot produce.
def check-format [
    model: string   # Transcription model id
    format: string  # Requested response format
] {
    if $format not-in $TEXT_FORMATS {
        error make {msg: $"unknown format ($format); expected one of ($TEXT_FORMATS | str join ', ')"}
    }
    if ($model | str starts-with "gpt-4o") and $format not-in ["json" "text"] {
        error make {msg: $"($model) only supports json/text; use -m whisper-1 for ($format)"}
    }
}

# Assemble the multipart form fields for an audio request.
#
# Optional values arrive as `any` because nushell has no optional type: a
# typed parameter rejects the null that an unset flag carries.
def audio-fields [
    model: string     # Transcription model id
    format: string    # Requested response format
    language: any     # ISO-639-1 hint, or null
    prompt: any       # Spelling/context hint, or null
    temperature: any  # Sampling temperature, or null
]: nothing -> record {
    {model: $model, response_format: $format}
    | merge (if $language == null { {} } else { {language: $language} })
    | merge (if $prompt == null { {} } else { {prompt: $prompt} })
    | merge (if $temperature == null { {} } else { {temperature: $temperature} })
}

# Upload audio to one of the /v1/audio routes, returning the raw response body.
def post-audio [
    route: string  # transcriptions | translations
    path: string   # Audio file to upload
    fields: record  # Multipart form fields
]: nothing -> string {
    # Checked here as well as in `http upload`: the header record below resolves
    # the API key eagerly, so without this a missing file reports "no openai key".
    let file: string = ($path | path expand --no-symlink)
    if not ($file | path exists) {
        let hint: string = if ($file | str contains "\\") {
            " (paths in quotes need no backslash escapes: use '3324 Beech Ave 4.m4a')"
        } else { "" }
        error make {msg: $"no such file: ($file)($hint)"}
    }

    (
        http upload $"($BASE)/audio/($route)" $file
        --headers {Authorization: $"Bearer (key)"}
        --fields $fields
        --label "openai"
    )
}

# Decode a response body to text: `json` wraps it, the rest are already text.
def text-of [
    body: string    # Raw response body
    format: string  # Requested response format
]: nothing -> string {
    if $format == "json" {
        $body | from json | http unwrap "openai" | get text
    } else {
        $body
    }
}

# Transcribe an audio file in its original language.
export def transcribe [
    path: string                              # Audio file (mp3, m4a, wav, webm, ...)
    --model (-m): string@model-names = "whisper-1"  # Transcription model
    --format (-f): string@format-names = "json"     # json | text | srt | vtt
    --language (-l): string                   # ISO-639-1 hint, e.g. en — improves accuracy
    --prompt (-p): string                     # Spelling/context hint for proper nouns
    --temperature (-t): float                 # Sampling temperature
]: nothing -> string {
    check-format $model $format
    let fields: record = (audio-fields $model $format $language $prompt $temperature)
    text-of (post-audio "transcriptions" $path $fields) $format
}

# Transcribe an audio file with timing detail (verbose_json).
#
# whisper-1 only: the gpt-4o models emit json/text alone.
export def "transcribe detailed" [
    path: string             # Audio file (mp3, m4a, wav, webm, ...)
    --language (-l): string  # ISO-639-1 hint, e.g. en — improves accuracy
    --prompt (-p): string    # Spelling/context hint for proper nouns
    --temperature (-t): float  # Sampling temperature
]: nothing -> record {
    let fields: record = (
        audio-fields "whisper-1" "verbose_json" $language $prompt $temperature
    )
    post-audio "transcriptions" $path $fields | from json | http unwrap "openai"
}

# Transcribe an audio file and translate it to English.
#
# The API supports whisper-1 only on this route.
export def translate [
    path: string                                 # Audio file (mp3, m4a, wav, webm, ...)
    --format (-f): string@format-names = "json"  # json | text | srt | vtt
    --prompt (-p): string                        # Spelling/context hint for proper nouns
    --temperature (-t): float                    # Sampling temperature
]: nothing -> string {
    check-format "whisper-1" $format
    let fields: record = (audio-fields "whisper-1" $format null $prompt $temperature)
    text-of (post-audio "translations" $path $fields) $format
}
