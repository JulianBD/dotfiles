# dotfiles

Portable macOS desktop environment, managed with [chezmoi](https://www.chezmoi.io/).

## Quick start

### Fresh Mac

```bash
# 1. Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Install chezmoi
brew install chezmoi

# 3. Init + apply (prompts for machine-specific values on first run)
chezmoi init <your-github-user> --source ~/dotfiles
chezmoi apply
```

`chezmoi apply` runs everything in order: deploys configs, then triggers brew bundle, mise install, and fisher plugin installation via [run scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/).

### Existing machine

```bash
chezmoi update    # git pull + apply in one step
```

## Package layers

Packages are managed in two layers. The rule of thumb: **brew for things that need native compilation or a GUI, mise for everything else**.

### Layer 0: Homebrew (`~/.Brewfile`)

Shells, native libs, GUI apps (casks), fonts, taps, and tools that mise can't install.

Edit: `chezmoi edit ~/.Brewfile` then `chezmoi apply`

Docs: [brew.sh](https://brew.sh/) / [Brewfile reference](https://github.com/Homebrew/homebrew-bundle#usage)

### Layer 1: mise (`~/.config/mise/config.toml`)

Dev runtimes, CLI tools, cargo/go/npm packages. Updated automatically when you `mise use -g <tool>@latest`.

Edit: `mise use -g <tool>` (updates config.toml in place), then `chezmoi add ~/.config/mise/config.toml` to capture it.

Docs: [mise.jdx.dev](https://mise.jdx.dev/)

### Machine types

The Brewfile uses conditionals based on `machine_type` (set during `chezmoi init`):

| Type | Description | Includes |
|------|-------------|----------|
| `work` | Work laptop (M3 Pro) | Everything: full dev tools, work casks (Edge, JIRA, AWS), VS Code |
| `dev` | Development/learning machine (i9 MBP) | Full dev tools, no work-specific casks |
| `casual` | Light use (M1 Air, low storage) | Core tools only, minimal casks, no build deps |

## What's managed

| Config | Path | Templated? | Docs |
|--------|------|-----------|------|
| AeroSpace | `~/.config/aerospace/aerospace.toml` | Yes (monitors, gaps) | [nikitabobko.github.io/AeroSpace](https://nikitabobko.github.io/AeroSpace/) |
| Fish | `~/.config/fish/` | Yes (secrets, cert paths) | [fishshell.com/docs](https://fishshell.com/docs/current/) |
| Ghostty | `~/.config/ghostty/` | No | [ghostty.org/docs](https://ghostty.org/docs) |
| SketchyBar | `~/.config/sketchybar/` | No | [felixkratz.github.io/SketchyBar](https://felixkratz.github.io/SketchyBar/) |
| Tuna | `~/Library/Application Support/Tuna/config.toml` | Yes (key codes) | — |
| Emacs | `~/.emacs.d/` | No | [gnu.org/software/emacs](https://www.gnu.org/software/emacs/) |

## Secrets

Secrets are **never committed to git**. They're prompted once during `chezmoi init` and stored in `~/.config/chezmoi/chezmoi.toml` (local-only, gitignored by chezmoi).

| Secret | Template variable | Prompted during init |
|--------|------------------|---------------------|
| JIRA API Token | `.jira_api_token` | Yes |

To update a secret: `chezmoi edit-config`, change the value, then `chezmoi apply`.

### Upgrading to 1Password (future)

When you have a machine with `op` CLI working, you can switch templates from `promptStringOnce` to `onepasswordRead` for automatic secret injection. Create a **Dotfiles** vault in 1Password, store secrets as items, and reference them in templates as:

```
{{ onepasswordRead "op://Dotfiles/JIRA API Token/credential" }}
```

Docs: [chezmoi 1Password integration](https://www.chezmoi.io/user-guide/password-managers/1password/) / [op CLI reference](https://developer.1password.com/docs/cli/reference/)

## Machine-specific values

On `chezmoi init`, you're prompted for values stored in `~/.config/chezmoi/chezmoi.toml` (gitignored):

| Value | Used by | Example |
|-------|---------|---------|
| `machine_type` | Brewfile conditionals | `work`, `dev`, `casual` |
| `primary_monitor` | AeroSpace workspace pinning | `1` |
| `secondary_monitor` | AeroSpace workspace pinning | `2` |
| `builtin_display_pattern` | AeroSpace gap override | `^built-in retina display$` |
| `outer_top_builtin` | AeroSpace gap for built-in | `14` |
| `outer_top_default` | AeroSpace gap default | `14` |
| `tuna_activate_keycode` | Tuna hotkey | `49` |
| `tuna_activate_modifiers` | Tuna hotkey | `256` |
| `tuna_leader_keycode` | Tuna leader mode | `49` |
| `tuna_leader_modifiers` | Tuna leader mode | `4096` |
| `cert_path` | Fish CA bundle exports | `~/certs/zscaler-bundle.pem` |

To change: `chezmoi edit-config` then `chezmoi apply`.

Docs: [chezmoi templates](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)

## Day-to-day

| Task | Command |
|------|---------|
| Edit a managed file | `chezmoi edit <target-path>` |
| See what would change | `chezmoi diff` |
| Apply changes | `chezmoi apply` |
| Add a new file | `chezmoi add <target-path>` |
| Pull remote + apply | `chezmoi update` |
| Re-enter machine values | `chezmoi init --source ~/dotfiles` |
| See managed files | `chezmoi managed` |
| Forget a file | `chezmoi forget <target-path>` |

After editing a file directly in `~/.config/...` instead of via `chezmoi edit`, recapture it:

```bash
chezmoi add ~/.config/path/to/file
```

Docs: [chezmoi daily operations](https://www.chezmoi.io/user-guide/daily-operations/)

## Run scripts

These run automatically during `chezmoi apply`:

| Script | Trigger | What it does |
|--------|---------|-------------|
| `run_once_set-default-browser.sh` | First apply only | Sets Helium as default browser via m-cli |
| `run_onchange_01-install-brew-packages.sh` | `~/.Brewfile` changes | `brew bundle --global` |
| `run_onchange_02-install-mise-tools.sh` | mise `config.toml` changes | `mise install` |
| `run_onchange_03-install-fisher-plugins.sh` | `fish_plugins` changes | `fisher update` |
| `run_after_apply-theme.sh` | Every apply | Applies current theme via elvish modules |

The `run_onchange_` scripts use chezmoi's [content hash trigger](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/#run-a-script-when-the-contents-of-another-file-changes): they include a hash comment of the watched file, so chezmoi detects when the file changes and re-runs the script.

Docs: [chezmoi scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)

## Theme system

Prot's emacs theme palettes ([ef-themes](https://github.com/protesilaos/ef-themes), [modus-themes](https://github.com/protesilaos/modus-themes), [doric-themes](https://github.com/protesilaos/doric-themes)) are the **single source of truth** for the entire desktop color scheme.

```
Prot's elisp palette definitions (installed via emacs package manager)
  → parse-palette.bb (babashka: extracts color data from elisp → JSON)
    → themes.json (local database of all palettes)
      → elvish dotfiles/theme module
        → ghostty theme file
        → sketchybar colors.sh
        → wallpaper (solid-color JPG at monitor resolution)
        → future consumers...
```

### Toolchain

| Tool | Role | Docs |
|------|------|------|
| Babashka | Parse elisp s-expressions → JSON | [babashka.org](https://babashka.org/) |
| Elvish | Theme management modules, config generation | [elv.sh](https://elv.sh/) |
| ImageMagick | Wallpaper generation | [imagemagick.org](https://imagemagick.org/) |
| m-cli | Wallpaper setting, macOS defaults | [github.com/rgcr/m-cli](https://github.com/rgcr/m-cli) |

### Usage (elvish)

```elvish
use dotfiles/theme
theme:sync              # rebuild palette DB from elpa sources
theme:list              # list all available themes
theme:pick              # interactive picker (peco)
theme:apply ef-autumn   # apply a specific theme
theme:current           # show current theme name
```

### Adding a new downstream consumer

Add a function to `~/.config/elvish/lib/dotfiles/generate.elv`. It receives the full palette map with all of Prot's semantic color names (bg-main, fg-main, red, red-warmer, red-cooler, etc.). See existing generators for examples.

## Fish functions

Custom functions live in `~/.config/fish/functions/`. These are **legacy** — the theme pipeline has moved to elvish modules, but these still work as fallbacks:

| Function | Purpose |
|----------|---------|
| `ghostty-theme` | Interactive theme picker (being replaced by `theme:pick` in elvish) |
| `sketchybar-colors` | Reads ghostty palette → generates `colors.sh` (being replaced by elvish) |

Fisher-managed functions (`_pure_*`, `bass`, etc.) are **not committed** — they're installed by the fisher `run_onchange_` script from `fish_plugins`.

Docs: [fish functions](https://fishshell.com/docs/current/language.html#functions) / [fisher](https://github.com/jorgebucaran/fisher)

## Generated files (do NOT commit)

| File | Regenerated by |
|------|---------------|
| `~/.config/ghostty/themes/*` | `theme:apply` (elvish, from palette database) |
| `~/.config/sketchybar/colors.sh` | `theme:apply` (elvish) |
| `~/.local/share/wallpapers/wallpaper-*.jpg` | `theme:apply` (imagemagick + m-cli) |
| `~/.config/dotfiles/themes.json` | `theme:sync` (babashka parses elpa sources) |
| `~/.config/fish/functions/_pure_*` | fisher |
| `~/.emacs.d/elpa/` | Emacs package manager |

## Repository structure

```
~/dotfiles/                              # chezmoi source directory
├── .chezmoi.toml.tmpl                   # machine-specific prompts
├── .chezmoiignore                       # files chezmoi skips
├── .gitignore
├── README.md
├── dot_Brewfile.tmpl                    # → ~/.Brewfile (machine_type conditionals)
├── dot_config/
│   ├── aerospace/aerospace.toml.tmpl    # → ~/.config/aerospace/aerospace.toml
│   ├── dotfiles/
│   │   └── parse-palette.bb            # → ~/.config/dotfiles/parse-palette.bb
│   ├── elvish/lib/dotfiles/            # → ~/.config/elvish/lib/dotfiles/
│   │   ├── theme.elv                   #   top-level: list, pick, apply, sync
│   │   ├── palette.elv                 #   palette database management
│   │   └── generate.elv               #   config generators (ghostty, sketchybar, wallpaper)
│   ├── fish/
│   │   ├── config.fish.tmpl            # → ~/.config/fish/config.fish
│   │   ├── fish_plugins                # → ~/.config/fish/fish_plugins
│   │   └── functions/                  # → ~/.config/fish/functions/
│   ├── ghostty/
│   │   ├── config                      # → ~/.config/ghostty/config
│   │   └── themes/                     # → ~/.config/ghostty/themes/ (generated by theme:apply)
│   ├── mise/config.toml                # → ~/.config/mise/config.toml
│   └── sketchybar/                     # → ~/.config/sketchybar/
├── dot_emacs.d/                         # → ~/.emacs.d/
├── private_Library/.../Tuna/
│   └── config.toml.tmpl                # → ~/Library/Application Support/Tuna/config.toml
├── run_once_set-default-browser.sh
├── run_onchange_01-install-brew-packages.sh.tmpl
├── run_onchange_02-install-mise-tools.sh.tmpl
├── run_onchange_03-install-fisher-plugins.sh.tmpl
└── run_after_apply-theme.sh
```

chezmoi naming conventions: `dot_` → `.`, `private_` → restricted perms, `executable_` → `+x`, `.tmpl` → Go template. See [chezmoi source state attributes](https://www.chezmoi.io/reference/source-state-attributes/).
