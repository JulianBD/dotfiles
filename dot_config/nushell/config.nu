# config.nu — nushell startup, managed by chezmoi.
#
# The modules themselves live in ~/.config/nushell/scripts alongside the rest
# of the chezmoi-managed config; this file is the bridge that loads them.
#
# They are loaded here rather than from an autoload directory because autoload
# did not fire on this machine (nushell 0.114.1, macOS) even with the files in
# $nu.user-autoload-dirs and config loading normally. config.nu is loaded
# unconditionally, so it is the dependable place.
#
# No trailing `*` on the `use` lines: that would strip the prefixes and
# collide, since zen and openai both export `key`, and bare `text`/`check`/
# `preview` are too generic.

$env.config.buffer_editor = "hx"
$env.config.show_banner = false

use ~/.config/nushell/scripts/zen.nu
use ~/.config/nushell/scripts/store.nu
use ~/.config/nushell/scripts/openai.nu
use ~/.config/nushell/scripts/pdf.nu
use ~/.config/nushell/scripts/typst.nu
use ~/.config/nushell/scripts/frg.nu

# Ctrl-G: turn the prompt buffer into a command, and leave the Enter to you.
#
# Type what you want in plain English, press Ctrl-G, and the buffer is replaced
# by a command you can read, edit, then run — or discard with Ctrl-C. Nothing
# executes on your behalf: `commandline edit -r` deliberately omits `--accept`.
#
# The call is synchronous and takes a second or two, so the prompt sits still
# until it returns.
def zen-suggest [] {
    let request: string = (commandline | str trim)
    if ($request | is-empty) { return }

    let suggestion: string = try {
        zen cmd $request
    } catch {|err|
        print $"\nzen cmd failed: ($err.msg | lines | first)"
        return
    }

    if ($suggestion | is-empty) { return }

    # `zen cmd` targets bash, which models write far more reliably than nu, so
    # the result is wrapped rather than pasted bare — bash syntax dropped into
    # a nu prompt is a syntax error, not a command. Single quotes are closed
    # and reopened around any the command itself contains.
    let quoted: string = ($suggestion | str replace --all "'" "'\\''")
    commandline edit -r $"bash -c '($quoted)'"
}

$env.config.keybindings = (
    $env.config.keybindings?
    | default []
    | where name != zen_suggest      # idempotent if this file is re-sourced
    | append {
        name: zen_suggest
        modifier: control
        keycode: char_g
        mode: [emacs vi_insert]
        event: { send: executehostcommand, cmd: "zen-suggest" }
    }
)
