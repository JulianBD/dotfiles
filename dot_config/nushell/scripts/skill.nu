# Skills: configuration, not code.
#
#   skill list
#   skill show olog
#   skill render --into ~/.claude/skills
#   "some prose" | zen skill olog
#
# A skill declares what to ask for, how the answer should be shaped, and which
# model should do it. One driver in zen.nu runs any of them, so adding a
# capability means adding a .ncl file rather than a nushell command.
#
# Nothing here talks to a provider: this module loads and renders, and zen.nu
# executes. Keeping that split is what stops the two importing each other.
#
# `skill render` writes standard SKILL.md folders — YAML frontmatter with name
# and description, then the body — which is the Agent Skills format rather than
# one of ours, so the same definition is readable by other harnesses.

use ./schema.nu

# Where the .ncl skill definitions live.
export def dir []: nothing -> string {
    $env.ZEN_SKILL_DIR? | default ($env.HOME | path join ".config" "nushell" "skills")
}

# Evaluate a nickel expression with `k` bound to one skill and `s` to the
# skill schema.
def evaluate [
    name: string        # Skill name
    expression: string  # Nickel expression
]: nothing -> any {
    let path: string = (dir | path join $"($name).ncl")
    if not ($path | path exists) {
        error make {msg: $"no such skill: ($name) \(looked in (dir))"}
    }
    let source: string = (
        $"let s = import \"skill.ncl\" in let k = import \"($path)\" in ($expression)"
    )
    let format: string = if $expression == "s.to_markdown k" { "raw" } else { "json" }
    let run = (
        $source | do { ^nickel export --format $format -I (schema dir) -I (dir) } | complete
    )
    if $run.exit_code != 0 {
        let detail: string = (
            $run.stderr | lines | where {|l| ($l | str trim) != "" } | first 4 | str join " "
        )
        error make {msg: $"skill ($name): ($detail)"}
    }
    if $format == "raw" { $run.stdout } else { $run.stdout | from json }
}

# Every skill, with what it is for.
export def list []: nothing -> table<name: string, output: string, description: string> {
    ls (dir)
    | where type == file
    | where {|row| $row.name | str ends-with ".ncl" }
    | each {|row| $row.name | path basename | str replace --regex '\.ncl$' '' }
    | where {|name| $name != "skill" }
    | each {|name|
        let k: record = (evaluate $name "k")
        {name: $k.name, output: $k.output, description: $k.description}
    }
}

# One skill's definition, as a record.
export def get [
    name: string  # Skill name
]: nothing -> record {
    evaluate $name "k"
}

# One skill rendered as SKILL.md.
export def show [
    name: string  # Skill name
]: nothing -> string {
    evaluate $name "s.to_markdown k"
}

# Write every skill as <into>/<name>/SKILL.md.
#
# The default target is ours; pass ~/.claude/skills to make the same
# definitions available to Claude Code.
export def render [
    --into: string  # Destination directory
]: nothing -> table<name: string, path: string> {
    let target: string = (
        $into | default ($env.HOME | path join ".config" "zen" "skills") | path expand --no-symlink
    )
    list | each {|row|
        let folder: string = ($target | path join $row.name)
        mkdir $folder
        let file: string = ($folder | path join "SKILL.md")
        show $row.name | save --force --raw $file
        {name: $row.name, path: $file}
    }
}
