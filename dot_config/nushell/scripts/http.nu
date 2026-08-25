# Shared HTTP plumbing for the API modules in this directory.
#
# Exports are deliberately *not* named `get`/`post`: this module is imported as
# `use http.nu`, so a command named `get` would land as `http get` and shadow
# the builtin. `http get-json` and friends sit alongside it instead.
#
# Signatures are annotated throughout, including structured record and table
# shapes. Nushell checks these at parse time, so a malformed literal is a
# parse error rather than a runtime surprise mid-request.

# The shape `complete` returns for an external command.
#
# Type aliases do not exist in nushell, so the shape is written out at each
# use site; this comment is the single definition of what it means.
#   record<exit_code: int, stdout: string, stderr: string>

# Read a key from the environment.
#
# Returns null when unset or empty, so the output type is `any`: nushell has no
# optional/nullable type to narrow it to.
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
    let result: record<exit_code: int, stdout: string, stderr: string> = (
        ^op read $reference | complete
    )
    if $result.exit_code != 0 {
        error make {msg: $"op read ($reference) failed: ($result.stderr | str trim)"}
    }
    $result.stdout | str trim
}

# Raise if a decoded body carries an API error payload, otherwise pass it through.
#
# Covers both shapes seen in practice: {error: {message: ...}} and
# {type: error, error: {...}}. Input and output are `any` because this is a
# transparent passthrough over every response shape the callers handle.
export def unwrap [
    label: string = "http"  # Prefix for the raised message, e.g. the API name
]: any -> any {
    let response = $in
    let payload = ($response | get -o error)
    if $payload != null {
        let message: string = if ($payload | describe | str starts-with "record") {
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
    url: string                    # Full request URL
    --headers (-H): record = {}    # Request headers
    --label (-l): string = "http"  # Prefix for raised messages
]: nothing -> record {
    http get --headers $headers --allow-errors $url | unwrap $label
}

# POST a JSON body and decode the response, raising on an API error payload.
export def post-json [
    url: string                    # Full request URL
    body: record                   # Serialized as the JSON request body
    --headers (-H): record = {}    # Request headers
    --label (-l): string = "http"  # Prefix for raised messages
]: nothing -> record {
    http post --content-type application/json --headers $headers --allow-errors $url $body
    | unwrap $label
}

# Render a record of name/value pairs as repeated curl arguments.
def curl-arguments [
    flag: string       # curl flag to repeat, e.g. -H or -F
    separator: string  # Joins name and value, e.g. ": " or "="
    pairs: record      # Names and values to render
]: nothing -> list<string> {
    $pairs
    | transpose name value
    | each {|pair| [$flag $"($pair.name)($separator)($pair.value)"] }
    | flatten
}

# Pull the most informative message out of a failed curl invocation.
#
# --fail-with-body prints the response body, which is where the real reason
# lives. With --retry the bodies of every attempt are concatenated, so the last
# JSON object in the stream — the final attempt — is the one that matters.
def error-detail [
    result: record<exit_code: int, stdout: string, stderr: string>  # From `complete`
]: nothing -> string {
    let body_lines: list<string> = ($result.stdout | lines)
    let starts: list<int> = (
        $body_lines
        | enumerate
        | where {|row| $row.item | str starts-with "{" }
        | get index
        | reverse
    )
    let message: any = (
        $starts
        | each {|start|
            try {
                $body_lines | skip $start | str join "\n" | from json | get -o error.message
            } catch {
                null
            }
        }
        | where {|candidate| $candidate != null }
        | get -o 0
    )
    if $message != null {
        return $message
    }
    [$result.stdout $result.stderr] | str join " " | str trim
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
    url: string                       # Full request URL
    file: string                      # Path to the file sent as the `file` part
    --headers (-H): record = {}       # Request headers
    --fields (-f): record = {}        # Extra form fields, as name/value pairs
    --label (-l): string = "http"     # Prefix for raised messages
    --max-size (-m): filesize = 25mb  # Reject larger files before uploading
]: nothing -> string {
    # Expand once, up front: `~` only survives as a literal when the path
    # arrives quoted or held in a variable.
    let path: string = ($file | path expand --no-symlink)
    if not ($path | path exists) {
        error make {msg: $"no such file: ($path)"}
    }

    let size: filesize = (ls $path | get 0.size)
    if $size > $max_size {
        error make {msg: $"($path) is ($size); this endpoint caps uploads at ($max_size). Shrink it first, e.g. ffmpeg -i in.m4a -ar 16000 -ac 1 -c:a libopus -b:a 16k out.ogg"}
    }

    let arguments: list<string> = (
        # --retry covers curl's transient set (408/429/5xx): large uploads to
        # some hosts intermittently draw a 502 from an edge proxy.
        # The numeric values are quoted: bare 30 and 2 parse as ints, which
        # makes this a list<oneof<string, int>> and fails the annotation.
        [-sS --fail-with-body --http1.1 --connect-timeout "30" --retry "2" -X POST $url]
        | append (curl-arguments "-H" ": " $headers)
        | append [-F $"file=@($path)"]
        | append (curl-arguments "-F" "=" $fields)
    )

    let result: record<exit_code: int, stdout: string, stderr: string> = (
        ^curl ...$arguments | complete
    )
    if $result.exit_code != 0 {
        error make {msg: $"($label): (error-detail $result)"}
    }
    $result.stdout | str trim
}
