# openai — the bits opencode zen does not proxy. Right now that means audio:
# zen serves no whisper/transcription models, so these talk to api.openai.com.
#
#   use openai.nu
#   openai transcribe recording.m4a
#   openai transcribe interview.mp3 --format srt | save interview.srt
#   ls *.m4a | each {|f| openai transcribe $f.name }
#
# Uploads go through `curl` rather than `http post --content-type
# multipart/form-data`: nushell names every multipart file part `filename="file"`,
# and OpenAI infers the audio container from that extension, so the native path
# is rejected as an invalid file format.

const BASE = "https://api.openai.com/v1"

# API key: $env.OPENAI_API_KEY, else `op read` of the ref in $env.OPENAI_API_KEY_OP.
export def key [] {
    if ("OPENAI_API_KEY" in $env) and (not ($env.OPENAI_API_KEY | is-empty)) {
        return $env.OPENAI_API_KEY
    }
    if "OPENAI_API_KEY_OP" in $env {
        let got = (^op read $env.OPENAI_API_KEY_OP | complete)
        if $got.exit_code == 0 { return ($got.stdout | str trim) }
        error make {msg: $"op read ($env.OPENAI_API_KEY_OP) failed: ($got.stderr | str trim)"}
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

def post-audio [route: string, path: string, form: list<string>, format: string] {
    if not ($path | path exists) {
        error make {msg: $"no such file: ($path)"}
    }
    # 25 MB is the hard API limit; fail here rather than after a long upload.
    let size = (ls $path | get 0.size)
    if $size > 25mb {
        error make {msg: $"($path) is ($size); the API caps uploads at 25 MB. Shrink it first, e.g. ffmpeg -i in.m4a -ar 16000 -ac 1 -c:a libopus -b:a 16k out.ogg"}
    }
    # --http2 against api.openai.com dies as `curl (92) INTERNAL_ERROR` partway
    # through multi-MB uploads; HTTP/1.1 uploads the same body fine.
    let args = (
        [-sS --fail-with-body --http1.1 --connect-timeout 30 -X POST $"($BASE)/audio/($route)"
         -H $"Authorization: Bearer (key)"
         -F $"file=@($path | path expand)"]
        | append $form
    )
    let got = (^curl ...$args | complete)
    if $got.exit_code != 0 {
        # --fail-with-body still prints the body, which is where the real reason lives.
        let detail = (
            try { $got.stdout | from json | get error.message }
            catch { [$got.stdout $got.stderr] | str join " " | str trim }
        )
        error make {msg: $"openai: ($detail)"}
    }
    let out = ($got.stdout | str trim)
    if $format in ["json" "verbose_json"] {
        let parsed = ($out | from json)
        let err = ($parsed | get -o error)
        if $err != null { error make {msg: $"openai: ($err.message)"} }
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
    let form = (
        [-F $"model=($model)" -F $"response_format=($format)"]
        | append (if $language == null { [] } else { [-F $"language=($language)"] })
        | append (if $prompt == null { [] } else { [-F $"prompt=($prompt)"] })
        | append (if $temperature == null { [] } else { [-F $"temperature=($temperature)"] })
    )
    post-audio "transcriptions" $path $form $format
}

# Transcribe *and* translate to English. whisper-1 only, per the API.
export def translate [
    path: string
    --format (-f): string = "json"
    --prompt (-p): string
    --temperature (-t): float
]: nothing -> any {
    let form = (
        [-F "model=whisper-1" -F $"response_format=($format)"]
        | append (if $prompt == null { [] } else { [-F $"prompt=($prompt)"] })
        | append (if $temperature == null { [] } else { [-F $"temperature=($temperature)"] })
    )
    post-audio "translations" $path $form $format
}
