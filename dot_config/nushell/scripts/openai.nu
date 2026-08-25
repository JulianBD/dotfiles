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

# Where `transcribe save` reads its defaults from.
def config-path []: nothing -> string {
    let override = (http env-key "TRANSCRIBE_CONFIG")
    if $override != null {
        return ($override | path expand --no-symlink)
    }
    $nu.home-dir | path join ".config/nushell/transcribe.toml"
}

# Defaults for `transcribe save`, with built-ins when the file is absent.
#
# Read at call time rather than at parse time, so editing the config takes
# effect without reloading the module.
def config []: nothing -> record<directory: string, name_template: string> {
    let defaults = {
        directory: "~/Documents/kb/raw-transcripts",
        name_template: "{date}_{slug}.{ext}"
    }
    let path: string = (config-path)
    if not ($path | path exists) {
        return $defaults
    }
    $defaults | merge (open $path | select -o directory name_template | compact --empty)
}

# Reduce arbitrary text to a filename-safe kebab-case slug.
def slugify [
    text: string  # Text to reduce
]: nothing -> string {
    $text
    | str lowercase
    | str replace --all --regex '[^a-z0-9]+' '-'
    | str trim --char '-'
}

# Fill a name template's {tokens} from a record of values.
def render-name [
    template: string  # Template string, e.g. "{date}_{slug}.{ext}"
    tokens: record    # Token names and their values
]: nothing -> string {
    $tokens
    | transpose name value
    | reduce --fold $template {|token, name|
        $name | str replace --all $"{($token.name)}" $token.value
    }
}

# Render the path `transcribe save` would write to, without calling the API.
export def "transcribe path" [
    path: string                                    # Audio file
    --name (-n): string                             # Slug source; defaults to the audio filename
    --model (-m): string@model-names = "whisper-1"  # Transcription model
    --format (-f): string@format-names = "json"     # json | text | srt | vtt
    --directory (-d): string                        # Override the configured directory
]: nothing -> string {
    let settings: record<directory: string, name_template: string> = (config)
    let stem: string = ($path | path parse | get stem)
    let target: string = (
        (if $directory == null { $settings.directory } else { $directory })
        | path expand --no-symlink
    )
    let tokens: record = {
        date: (date now | format date "%Y-%m-%d"),
        time: (date now | format date "%H-%M"),
        slug: (slugify (if $name == null { $stem } else { $name })),
        stem: $stem,
        model: $model,
        format: $format,
        ext: (if $format in ["json" "text"] { "txt" } else { $format })
    }
    $target | path join (render-name $settings.name_template $tokens)
}

# Transcribe an audio file and save it, returning the path written.
#
# The directory and filename template come from the config file; see
# `openai transcribe path` to preview the destination.
export def "transcribe save" [
    path: string                                    # Audio file
    --name (-n): string                             # Slug source; defaults to the audio filename
    --model (-m): string@model-names = "whisper-1"  # Transcription model
    --format (-f): string@format-names = "json"     # json | text | srt | vtt
    --language (-l): string                         # ISO-639-1 hint, e.g. en
    --prompt (-p): string                           # Spelling/context hint for proper nouns
    --temperature (-t): float                       # Sampling temperature
    --directory (-d): string                        # Override the configured directory
    --force                                         # Overwrite an existing transcript
]: nothing -> string {
    check-format $model $format
    let destination: string = (
        if $directory == null {
            transcribe path $path --name $name --model $model --format $format
        } else {
            transcribe path $path --name $name --model $model --format $format --directory $directory
        }
    )
    if ($destination | path exists) and (not $force) {
        error make {msg: $"($destination) exists; pass --force to overwrite"}
    }

    let fields: record = (audio-fields $model $format $language $prompt $temperature)
    let text: string = (text-of (post-audio "transcriptions" $path $fields) $format)

    mkdir ($destination | path dirname)
    $text | save --force $destination
    $destination
}
