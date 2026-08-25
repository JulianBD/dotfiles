# Nickel as JSON's type system.
#
#   use schema.nu
#   schema json proposal      # JSON Schema, for response_format
#   $record | schema check proposal
#
# Each schema is one .ncl file describing a type once, exporting two views of
# it: `json_schema` for the decoder to enforce during generation, and
# `Contract` for checking the value on the way back. Generating both from one
# description is the point — maintaining a JSON Schema beside a validator is
# how the two come to disagree.
#
# Nickel evaluation costs about 30ms, which is nothing beside the network call
# these schemas are used for, so nothing here is cached.

# Where the .ncl files live.
export def dir []: nothing -> string {
    $env.ZEN_SCHEMA_DIR? | default ($env.HOME | path join ".config" "nushell" "schemas")
}

# Path of one schema, checked so the failure names the file rather than
# surfacing as a nickel import error.
def schema-path [
    name: string  # Schema name, without the .ncl
]: nothing -> string {
    let path: string = (dir | path join $"($name).ncl")
    if not ($path | path exists) {
        error make {msg: $"no such schema: ($name) \(looked in (dir))"}
    }
    $path
}

# Evaluate a nickel expression against a schema, returning parsed JSON.
#
# `-I` puts the schema directory on nickel's import path, so the .ncl files can
# import each other by bare name regardless of where nu was invoked from.
def evaluate [
    name: string        # Schema name
    expression: string  # Nickel expression, with `s` bound to the schema
]: nothing -> any {
    let path: string = (schema-path $name)
    let source: string = $"let s = import \"($path)\" in ($expression)"

    let run = ($source | do { ^nickel export --format json -I (dir) } | complete)
    if $run.exit_code != 0 {
        let detail: string = (
            $run.stderr
            | lines
            | where {|line| ($line | str trim) != "" }
            | first 4
            | str join " "
        )
        error make {msg: $"schema ($name): ($detail)"}
    }
    $run.stdout | from json
}

# The JSON Schema for a type, ready to drop into `response_format`.
export def json [
    name: string  # Schema name
]: nothing -> record {
    evaluate $name "s.json_schema"
}

# Check a value against a schema, returning it unchanged or raising.
#
# This is the half JSON Schema cannot do: a contract may relate one part of a
# document to another, which no decoder-level mould can enforce.
export def check [
    name: string  # Schema name
]: any -> any {
    let value = $in

    # Written to a file rather than inlined: nickel is not a JSON superset —
    # records are `{ key = value }`, not `{"key": value}` — so a JSON literal
    # pasted into an expression is a syntax error. Importing a .json file is
    # the supported route, and nickel parses it natively.
    let staged: string = (mktemp --tmpdir --suffix .json "zen-check-XXXXXX")
    $value | to json --raw | save --force --raw $staged
    let outcome = (
        try {
            {ok: true, value: (evaluate $name $"\(import \"($staged)\") | s.Contract")}
        } catch {|err|
            {ok: false, value: $err.msg}
        }
    )
    rm --force $staged

    if not $outcome.ok { error make {msg: $outcome.value} }
    $outcome.value
}
