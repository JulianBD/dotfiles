# The graph store: an append-only log of entries, folded into nodes.
#
# Entries are immutable. Nothing is ever edited in place; a change is a new
# entry with the same identifier, and the fold takes the newest. This is what
# makes the log the root (see models/schema-design.md section 4) and everything
# derived from it a view.
#
# Deliberately absent: edges, polars, contracts. Nodes alone are enough to
# exercise the round-trip property, which is the point of this rung.

# Where the store lives. The layers are kept separate under one root:
#
#     ~/Documents/kb/entries.jsonl   the graph -- append-only, the store
#     ~/Documents/kb/kb-vault/       the MyST projection -- regenerable
#     ~/Documents/kb/raw-transcripts/ capture -- primary, nothing maps into it
#
# The projection sits beside the store rather than inside it, so that deleting
# and regenerating the vault cannot touch the log it was rendered from.
export def home []: nothing -> string {
    $env | get -o KB_HOME | default ($nu.home-dir | path join "Documents/kb")
}

# The projection target: what Obsidian opens.
export def vault []: nothing -> string {
    home | path join "kb-vault"
}

export def log []: nothing -> string {
    let dir: string = (home)
    mkdir $dir
    $dir | path join "entries.jsonl"
}

# A globally unique identifier, written into the artifact so that a file edited
# on a device that has never seen the store can still be reconciled.
export def new-id [prefix: string = "n"]: nothing -> string {
    $"($prefix)-(random chars --length 8 | str lowercase)"
}

# Append one entry. Returns what was written.
export def append-entry [entry: record]: nothing -> record {
    let full: record = ($entry | merge {at: (date now | format date "%+")})
    # save --append writes no trailing newline, so the record carries its own.
    $"($full | to json --raw)\n" | save --append (log)
    $full
}

export def entries []: nothing -> table {
    let file: string = (log)
    if not ($file | path exists) { return [] }
    open --raw $file
    | lines
    | where {|line| ($line | str trim) != "" }
    | each {|line| $line | from json }
}

# Fold the log into current nodes: newest entry per identifier wins.
export def nodes []: nothing -> table {
    let all: table = (entries | where op == "node")
    if ($all | is-empty) { return [] }
    $all | group-by id | values | each {|group| $group | last } | reject op at
}

export def add [
    text: string
    --kind (-k): string = "note"
    --id: string
]: nothing -> record {
    let identifier: string = (if $id == null { new-id } else { $id })
    append-entry {op: "node", id: $identifier, kind: $kind, text: $text}
}
