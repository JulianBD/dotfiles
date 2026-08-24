# Shared HTTP plumbing for the API modules in this directory.
#
# Exports are deliberately *not* named `get`/`post`: this module is imported as
# `use http.nu`, so a command named `get` would land as `http get` and shadow
# the builtin. `http get-json` and friends sit alongside it instead.

# Read a key from the environment; null when unset or empty.
export def env-key [name: string]: nothing -> any {
    if ($name in $env) and (not ($env | get $name | is-empty)) {
        $env | get $name
    } else {
        null
    }
}

# Read a secret from 1Password by op:// reference.
export def op-key [reference: string]: nothing -> string {
    let got = (^op read $reference | complete)
    if $got.exit_code != 0 {
        error make {msg: $"op read ($reference) failed: ($got.stderr | str trim)"}
    }
    $got.stdout | str trim
}

# Raise if a decoded body carries an API error payload, else pass it through.
# Covers both shapes seen in practice: {error: {message}} and {type: error, error: {...}}.
export def unwrap [label: string]: any -> any {
    let resp = $in
    let err = ($resp | get -o error)
    if $err != null {
        let msg = (if ($err | describe | str starts-with "record") {
            $err | get -o message | default ($err | to nuon)
        } else {
            $err | into string
        })
        error make {msg: $"($label): ($msg)"}
    }
    $resp
}

export def get-json [url: string, headers: record, label: string = "http"]: nothing -> any {
    http get --headers $headers --allow-errors $url | unwrap $label
}

export def post-json [url: string, headers: record, body: record, label: string = "http"]: nothing -> any {
    http post --content-type application/json --headers $headers --allow-errors $url $body
    | unwrap $label
}

# Multipart file upload, via curl rather than `http post --content-type
# multipart/form-data`. Two reasons the native path does not work:
#
#   - nushell labels every file part `filename="file"`, with no way to set the
#     part filename independently of the field name (nushell#15516). APIs that
#     sniff the format from that extension reject the upload.
#   - HTTP/2 uploads of multi-MB bodies to some hosts abort mid-stream as
#     `curl (92) INTERNAL_ERROR`; curl can be pinned to HTTP/1.1, which works.
#
# `fields` are extra -F form fields as name=value pairs. Returns the raw body.
export def upload [
    url: string
    headers: record
    file: string
    fields: record = {}
    --label: string = "http"
    --max-size: filesize = 25mb
]: nothing -> string {
    # Expand once, up front: `~` is only expanded by nushell in bare words, so a
    # quoted or variable-held path arrives here literal.
    let file = ($file | path expand --no-symlink)
    if not ($file | path exists) {
        error make {msg: $"no such file: ($file)"}
    }
    let size = (ls $file | get 0.size)
    if $size > $max_size {
        error make {msg: $"($file) is ($size); this endpoint caps uploads at ($max_size). Shrink it first, e.g. ffmpeg -i in.m4a -ar 16000 -ac 1 -c:a libopus -b:a 16k out.ogg"}
    }

    let header_args = ($headers | transpose name value | each {|h| [-H $"($h.name): ($h.value)"] } | flatten)
    let field_args = ($fields | transpose name value | each {|f| [-F $"($f.name)=($f.value)"] } | flatten)
    let args = (
        # --retry covers curl's transient set (408/429/5xx): large uploads to
        # api.openai.com intermittently draw a 502 from the Cloudflare edge.
        [-sS --fail-with-body --http1.1 --connect-timeout 30 --retry 2 -X POST $url]
        | append $header_args
        | append [-F $"file=@($file)"]
        | append $field_args
    )

    let got = (^curl ...$args | complete)
    if $got.exit_code != 0 {
        # --fail-with-body still prints the body, which is where the real reason lives.
        let detail = (
            try { $got.stdout | from json | get error.message }
            catch { [$got.stdout $got.stderr] | str join " " | str trim }
        )
        error make {msg: $"($label): ($detail)"}
    }
    $got.stdout | str trim
}
