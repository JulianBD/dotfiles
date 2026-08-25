# frg — run Forge models.
#
#   use frg.nu
#   frg check olog.frg     # one model
#   frg check              # every .frg in the current directory
#   frg check | where not ok
#
# Named `frg` rather than `forge` because steel's package manager owns that
# name on PATH; `.frg` is the file extension anyway.
#
# A Forge model is a Racket program, so `racket model.frg` is the whole story.
# Exit code 0 means every test passed, 1 means at least one failed.

# Run one or more Forge models, reporting the tests in each.
#
# Models are expected to set `option run_sterling off`; without it Forge opens
# the Sterling visualiser and blocks on stdin, and this command will hang.
#
# `passed` and `failed` are counted from Forge's output, so a model that sets
# `option verbose 0` reports 0 passed even when its tests pass — that option
# suppresses the per-test lines. `ok` comes from the exit code and is always
# authoritative.
export def check [
    ...files: string  # Forge models; defaults to *.frg here
    --quiet (-q)      # Suppress the output of failing models
]: nothing -> table<file: string, passed: int, failed: int, ok: bool> {
    let targets: list<string> = if ($files | is-empty) {
        ls *.frg | get name
    } else {
        $files
    }
    if ($targets | is-empty) {
        error make {msg: "no .frg files given, and none in the current directory"}
    }

    $targets | each {|file|
        let path: string = ($file | path expand --no-symlink)
        if not ($path | path exists) {
            error make {msg: $"no such file: ($path)"}
        }

        let result: record<exit_code: int, stdout: string, stderr: string> = (
            ^racket $path | complete
        )
        let output: string = $"($result.stdout)($result.stderr)"
        let ok: bool = ($result.exit_code == 0)
        if (not $ok) and (not $quiet) {
            print ($output | lines | where {|line| $line =~ "Failed test|error" } | str join "\n")
        }
        {
            file: ($path | path basename),
            passed: ($output | lines | where {|line| $line =~ "Test passed" } | length),
            failed: ($output | lines | where {|line| $line =~ "Failed test" } | length),
            ok: $ok
        }
    }
}
