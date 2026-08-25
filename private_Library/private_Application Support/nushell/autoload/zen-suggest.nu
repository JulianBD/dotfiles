# Ctrl-G: turn the prompt buffer into a command, and leave the Enter to you.
#
# Type what you want in plain English, press Ctrl-G, and the buffer is replaced
# by a command you can read, edit, and then run — or discard with Ctrl-C.
# `commandline edit -r` deliberately does not use `--accept`: nothing here
# executes on your behalf, which is the whole point of this shape.
#
# The call is synchronous and takes a second or two, so the prompt will sit
# still until it returns.

def zen-suggest [] {
    let request: string = (commandline | str trim)
    if ($request | is-empty) { return }

    let suggestion: string = try {
        zen cmd $request
    } catch {|err|
        # Leave the buffer alone on failure; the message is enough of a signal.
        print $"\nzen cmd failed: ($err.msg)"
        return
    }

    if ($suggestion | is-empty) { return }

    # `zen cmd` targets bash, which models write far more reliably than nu, so
    # the result is wrapped rather than pasted bare — bash syntax dropped into
    # a nu prompt is a syntax error, not a command. Single quotes are closed
    # and reopened around any the command itself contains.
    let quoted: string = ($suggestion | str replace --all "'" "'\''")
    commandline edit -r $"bash -c '($quoted)'"
}

$env.config.keybindings = (
    $env.config.keybindings?
    | default []
    | append {
        name: zen_suggest
        modifier: control
        keycode: char_g
        mode: [emacs vi_insert]
        event: { send: executehostcommand, cmd: "zen-suggest" }
    }
)
