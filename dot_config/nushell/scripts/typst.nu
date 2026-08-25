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
    --title (-t): string  # Browser tab title; defaults to the filename
]: nothing -> table<file: string, job: int> {
    # Globs are expanded here rather than declared as a `glob` parameter, so
    # that `typst preview *.typ` and an explicit list behave the same way.
    let targets: list<string> = if ($files | is-empty) {
        ls *.typ | get name
    } else {
        $files | each {|file| if ($file =~ '[*?]') { glob $file } else { [$file] } } | flatten
    }
    if ($targets | is-empty) {
        error make {msg: "no .typ files matched, and none in the current directory"}
    }
    if $title != null and ($targets | length) > 1 {
        error make {msg: "--title names a single tab; pass one file, or let each tab take its filename"}
    }

    $targets | each {|file|
        let path: string = ($file | path expand --no-symlink)
        if not ($path | path exists) {
            error make {msg: $"no such file: ($path)"}
        }
        # tinymist titles the tab after the input file unless told otherwise.
        # The favicon is a data URI hardcoded in its served HTML, so tabs can
        # differ by name but not by icon.
        let tab: string = (if $title == null { $path | path basename } else { $title })
        {
            file: ($path | path basename),
            job: (job spawn { ^tinymist preview --open --page-title $tab $path })
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
