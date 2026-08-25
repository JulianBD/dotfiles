# Projection to MyST and back.
#
# A block break is a node boundary. Its JSON payload carries the fields with no
# structural correlate -- identifier, kind, state -- while everything after it is
# ordinary markdown whose shape carries the structure.
#
# The contract this module exists to satisfy is one equation:
#
#     parse . render = id
#
# proven as a split monomorphism in models/olog.frg (factsForceInjectivity) and
# instantiated for rendering in models/rung6-projection.frg (renderIsInjective).
# Because the contract is an equation rather than an implementation, this parser
# is replaceable -- a Rust extension is the eventual destination.

# A body line that would itself read as a block break is escaped with a
# backslash, which is markdown's own escape and renders invisibly. Without this
# a node whose text discusses the format splits into two on the way back, and
# worse, arbitrary nodes can be injected through content. Injectivity is the
# whole contract, so this is not a nicety.
def is-break-like [line: string]: nothing -> bool {
    ($line | str trim --left --char "\\") | str starts-with "+++"
}

def escape-body [text: string]: nothing -> string {
    $text | lines | each {|line|
        if (is-break-like $line) { "\\" + $line } else { $line }
    } | str join "\n"
}

def unescape-body [text: string]: nothing -> string {
    $text | lines | each {|line|
        if (($line | str starts-with "\\") and (is-break-like $line)) {
            $line | str substring 1..
        } else { $line }
    } | str join "\n"
}

export def render []: table -> string {
    $in
    | each {|node|
        let meta: string = ($node | reject text | to json --raw)
        let body: string = (escape-body ($node.text | str trim))
        $"+++ ($meta)\n\n($body)\n"
    }
    | str join "\n"
}

export def parse []: string -> table {
    mut out: list<any> = []
    mut meta: any = null
    mut buffer: list<string> = []

    for line in ($in | lines) {
        if ($line | str starts-with "+++ ") {
            if $meta != null {
                $out = ($out | append ($meta | merge {text: (unescape-body ($buffer | str join "\n" | str trim))}))
            }
            $meta = ($line | str substring 4.. | from json)
            $buffer = []
        } else {
            $buffer = ($buffer | append $line)
        }
    }
    if $meta != null {
        $out = ($out | append ($meta | merge {text: (unescape-body ($buffer | str join "\n" | str trim))}))
    }
    $out
}
