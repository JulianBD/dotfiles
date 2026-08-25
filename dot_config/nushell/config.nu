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
use ~/.config/nushell/scripts/keys.nu
use ~/.config/nushell/scripts/openai.nu
use ~/.config/nushell/scripts/pdf.nu
use ~/.config/nushell/scripts/typst.nu
use ~/.config/nushell/scripts/frg.nu

# --- Keybindings ---
#
# The handlers live in keys.nu so they can be called by hand and tested; this
# only binds them. Nothing here executes a command on your behalf: the two that
# produce one rewrite the prompt buffer and stop, because `commandline edit -r`
# omits `--accept`.
#
#   Ctrl-G  English in the buffer -> a runnable command in the buffer
#   Alt-G   explain what is in the buffer, leaving it untouched
#   Alt-F   the last command failed -> a corrected one in the buffer
#   Ctrl-O  open the buffer in $env.config.buffer_editor
#
# Bindings are plain records, so they are filtered before being appended and
# re-sourcing this file replaces rather than stacks them.
$env.config.keybindings = (
    $env.config.keybindings?
    | default []
    | where name not-in [zen_suggest zen_explain zen_fix zen_editor]
    | append [
        {
            name: zen_suggest
            modifier: control
            keycode: char_g
            mode: [emacs vi_insert]
            event: { send: executehostcommand, cmd: "keys suggest" }
        }
        {
            name: zen_explain
            modifier: alt
            keycode: char_g
            mode: [emacs vi_insert]
            event: { send: executehostcommand, cmd: "keys explain" }
        }
        {
            name: zen_fix
            modifier: alt
            keycode: char_f
            mode: [emacs vi_insert]
            event: { send: executehostcommand, cmd: "keys fix" }
        }
        {
            name: zen_editor
            modifier: control
            keycode: char_o
            mode: [emacs vi_insert]
            event: { send: openeditor }
        }
    ]
)
