# typst — preview helpers around tinymist.
#
#   use typst.nu
#   typst preview olog.typ        # one file, opens a browser tab
#   typst preview                 # every .typ in the current directory
#   typst jobs                    # what is currently being previewed
#   typst stop                    # shut the preview servers down

# Start a tinymist preview server per file, each in its own browser tab.
#
# Servers run as background jobs and keep recompiling on save. With no
# arguments, previews every .typ file in the current directory.
export def preview [
    ...files: string  # Typst files; defaults to *.typ here
]: nothing -> table<file: string, job: int> {
    let targets: list<string> = if ($files | is-empty) {
        ls *.typ | get name
    } else {
        $files
    }
    if ($targets | is-empty) {
        error make {msg: "no .typ files given, and none in the current directory"}
    }

    $targets | each {|file|
        let path: string = ($file | path expand --no-symlink)
        if not ($path | path exists) {
            error make {msg: $"no such file: ($path)"}
        }
        {
            file: ($path | path basename),
            job: (job spawn { ^tinymist preview --open $path })
        }
    }
}

# Background jobs currently running, which is where previews live.
export def jobs []: nothing -> table {
    job list
}

# Stop every preview server started by `typst preview`.
export def stop []: nothing -> nothing {
    job list | get id | each {|id| job kill $id } | ignore
}
