# Where zen keeps what it has been asked and what it answered.
#
#   use store.nu
#   store history | last 5
#   store session load work
#   store sessions
#
# Two stores, deliberately separate:
#
#   history.jsonl           every call, append-only, never replayed
#   sessions/<name>.jsonl   resumable conversations, replayed into later requests
#
# The split is a guarantee about the *read* path. `session load` is the only
# reader that feeds anything back to a model, and it cannot see history, so a
# one-off call leaves a record without leaving state. Recording a request does
# not make a later request depend on it; only replaying it does.
#
# Keeping them apart also lets them age out under different policies, since
# nothing depends on history: it can be rotated or truncated freely, whereas a
# session must be kept whole or not at all.

# Base directory for both stores. $ZEN_DATA_DIR overrides.
export def root []: nothing -> string {
    $env.ZEN_DATA_DIR? | default ($env.HOME | path join ".local" "share" "zen") | path expand --no-symlink
}

# Path of the append-only log of every call.
export def "history path" []: nothing -> string {
    root | path join "history.jsonl"
}

# Path of one named session's ledger.
export def "session path" [
    name: string  # Session name
]: nothing -> string {
    root | path join "sessions" $"($name).jsonl"
}

# Append one record to a JSONL file, creating its directory if needed.
#
# `to json --raw` keeps each record on a single line, which is what makes the
# file appendable and safe to truncate at a line boundary.
def append-line [
    path: string    # Destination file
    record: record  # Row to write
]: nothing -> nothing {
    mkdir ($path | path dirname)
    $"($record | to json --raw)\n" | save --append --raw $path
}

# Read a JSONL file as a table, empty when the file does not exist.
def read-lines [
    path: string  # Source file
]: nothing -> table {
    if not ($path | path exists) { return [] }
    open --raw $path
    | lines
    | where {|line| ($line | str trim) != "" }
    | each {|line| $line | from json }
}

# Record one completed call in the history log.
#
# Written for every call, session or not. Nothing ever reads this back into a
# request; it exists to be grepped, and to make cost visible after the fact.
export def "history append" [
    entry: record  # {model, protocol, kind, session, prompt, reply, usage}
]: nothing -> nothing {
    append-line (history path) ({timestamp: (date now | format date "%+")} | merge $entry)
}

# The whole history, oldest first.
export def history []: nothing -> table {
    read-lines (history path)
}

# Append turns to a session ledger.
#
# Turns are stored normalized — `{role, content}` — rather than in any
# provider's wire shape, so a session started against one model can be
# continued against another. Rendering to a provider body happens at send time.
export def "session append" [
    name: string        # Session name
    turns: list<record> # Normalized turns: {role, content}
]: nothing -> nothing {
    let path: string = (session path $name)
    let stamp: string = (date now | format date "%+")
    for turn in $turns {
        append-line $path ({timestamp: $stamp} | merge $turn)
    }
}

# Load a session's turns in normalized form, ready to prepend to a request.
#
# The only reader that feeds stored data back to a model. Returns an empty list
# for an unknown session, so starting and resuming are the same code path.
export def "session load" [
    name: string  # Session name
]: nothing -> list<record> {
    let turns: table = (read-lines (session path $name))
    if ($turns | is-empty) { return [] }
    $turns | select role content
}

# Every session, most recently used first.
export def sessions []: nothing -> table {
    let dir: string = (root | path join "sessions")
    if not ($dir | path exists) { return [] }
    ls $dir
    | where type == file and ($it.name | str ends-with ".jsonl")
    | insert turns {|row| read-lines $row.name | length }
    | update name {|row| $row.name | path basename | str replace --regex '\.jsonl$' '' }
    | select name turns modified
    | sort-by modified --reverse
}

# Delete a session ledger. History is untouched.
export def "session drop" [
    name: string  # Session name
]: nothing -> nothing {
    let path: string = (session path $name)
    if not ($path | path exists) {
        error make {msg: $"no such session: ($name)"}
    }
    rm $path
}
