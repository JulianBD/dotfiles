# Loaded automatically by nushell at startup: everything in this directory is
# sourced before the prompt appears. The modules themselves live with the rest
# of the dotfiles in ~/.config/nushell/scripts, because that is where the
# chezmoi-managed config lives; this file is only the bridge.
#
# No trailing `*`: that would strip the prefixes and collide, since zen and
# openai both export `key`, and bare `text`/`check`/`preview` are too generic.
#
# Adding a module means adding a line here.

use ~/.config/nushell/scripts/zen.nu
use ~/.config/nushell/scripts/openai.nu
use ~/.config/nushell/scripts/pdf.nu
use ~/.config/nushell/scripts/typst.nu
use ~/.config/nushell/scripts/frg.nu
