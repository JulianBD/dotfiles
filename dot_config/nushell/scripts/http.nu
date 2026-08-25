# Shared HTTP plumbing for the API modules in this directory.
#
# Exports are deliberately *not* named `get`/`post`: this module is imported as
# `use http.nu`, so a command named `get` would land as `http get` and shadow
# the builtin. `http get-json` and friends sit alongside it instead.

# Read a key from the environment, returning null when unset or empty.
export def env-key [
    name: string  # Environment variable name
]: nothing -> any {
    if ($name in $env) and (not ($env | get $name | is-empty)) {
        $env | get $name
    } else {
        null
    }
}

# Read a secret from 1Password by reference.
export def op-key [
    reference: string  # An op:// reference, as accepted by `op read`
]: nothing -> string {
    let result = (^op read $reference | complete)
    if $result.exit_code != 0 {
        error make {msg: $"op read ($reference) failed: ($result.stderr | str trim)"}
    }
    $result.stdout | str trim
}

# Raise if a decoded body carries an API error payload, otherwise pass it through.
#
# Covers both shapes seen in practice: {error: {message: ...}} and
# {type: error, error: {...}}.
export def unwrap [
    label: string = "http"  # Prefix for the raised message, e.g. the API name
]: any -> any {
    let response = $in
    let payload = ($response | get -o error)
    if $payload != null {
        let message = if ($payload | describe | str starts-with "record") {
            $payload | get -o message | default ($payload | to nuon)
        } else {
            $payload | into string
        }
        error make {msg: $"($label): ($message)"}
    }
    $response
}

# GET a URL and decode the JSON body, raising on an API error payload.
export def get-json [
    url: string                # Full request URL
    --headers (-H): record = {}  # Request headers
    --label (-l): string = "http"  # Prefix for raised messages
]: nothing -> any {
    http get --headers $headers --allow-errors $url | unwrap $label
}

# POST a JSON body and decode the response, raising on an API error payload.
export def post-json [
    url: string                # Full request URL
    body: record               # Serialized as the JSON request body
    --headers (-H): record = {}  # Request headers
    --label (-l): string = "http"  # Prefix for raised messages
]: nothing -> any {
    http post --content-type application/json --headers $headers --allow-errors $url $body
    | unwrap $label
}

# Upload a file as multipart/form-data, returning the raw response body.
#
# Shells out to curl rather than using `http post --content-type
# multipart/form-data`, for two reasons:
#
#   - nushell labels every file part `filename="file"`, with no way to set the
#     part filename independently of the field name (nushell#15516). APIs that
#     sniff the format from that extension reject the upload.
#   - HTTP/2 uploads of multi-MB bodies to some hosts abort mid-stream as
#     `curl (92) INTERNAL_ERROR`; curl can be pinned to HTTP/1.1, which works.
export def upload [
    url: string                      # Full request URL
    file: string                     # Path to the file sent as the `file` part
    --headers (-H): record = {}      # Request headers
    --fields (-f): record = {}       # Extra form fields, as name/value pairs
    --label (-l): string = "http"    # Prefix for raised messages
    --max-size (-m): filesize = 25mb  # Reject larger files before uploading
]: nothing -> string {
    # Expand once, up front: `~` only survives as a literal when the path
    # arrives quoted or held in a variable.
    let path = ($file | path expand --no-symlink)
    if not ($path | path exists) {
        error make {msg: $"no such file: ($path)"}
    }

    let size = (ls $path | get 0.size)
    if $size > $max_size {
        error make {msg: $"($path) is ($size); this endpoint caps uploads at ($max_size). Shrink it first, e.g. ffmpeg -i in.m4a -ar 16000 -ac 1 -c:a libopus -b:a 16k out.ogg"}
    }

    let header_arguments = (
        $headers
        | transpose name value
        | each {|header| [-H $"($header.name): ($header.value)"] }
        | flatten
    )
    let field_arguments = (
        $fields
        | transpose name value
        | each {|field| [-F $"($field.name)=($field.value)"] }
        | flatten
    )
    let arguments = (
        # --retry covers curl's transient set (408/429/5xx): large uploads to
        # some hosts intermittently draw a 502 from an edge proxy.
        [-sS --fail-with-body --http1.1 --connect-timeout 30 --retry 2 -X POST $url]
        | append $header_arguments
        | append [-F $"file=@($path)"]
        | append $field_arguments
    )

    let result = (^curl ...$arguments | complete)
    if $result.exit_code != 0 {
        # --fail-with-body still prints the body, which is where the real reason lives.
        let detail = (
            try { $result.stdout | from json | get error.message }
            catch { [$result.stdout $result.stderr] | str join " " | str trim }
        )
        error make {msg: $"($label): ($detail)"}
    }
    $result.stdout | str trim
}
