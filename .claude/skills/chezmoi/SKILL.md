---
name: chezmoi
description: Manage this chezmoi dotfiles repo — add/edit/apply/diff files, write templates, create run scripts, handle machine-specific config, and debug deployment issues. Use whenever the user wants to change a dotfile, add/remove a package or tool, modify any app config, work with the theme pipeline, or asks about chezmoi state. Also trigger when the user mentions Brewfile, mise, sketchybar, aerospace, ghostty, helix, fish, elvish, zed, or Emacs config.
argument-hint: [what to do]
allowed-tools: Bash(chezmoi *) Bash(elvish *) Bash(brew services *) Bash(sketchybar *)
---

## How this repo works

All dotfiles live in `~/.local/share/chezmoi/` (this directory). Chezmoi computes a target state from these source files — evaluating templates, stripping prefixes, setting permissions — and writes the result to `~/` when you run `chezmoi apply`.

The cardinal rule: edit source files here, never the deployed files under `~/`. If the user points at a target path like `~/.config/ghostty/config`, find its source with `chezmoi source-path ~/.config/ghostty/config` and edit that instead.

## Chezmoi by example (from this repo)

### Templates (`.tmpl` suffix)

Any source file ending in `.tmpl` is a Go template evaluated before deployment. Template data comes from `~/.config/chezmoi/chezmoi.toml` (gitignored, generated from `.chezmoi.toml.tmpl` during `chezmoi init`).

**Conditionals on machine type** — the Brewfile gates packages per machine:
```
{{ if eq .machine_type "work" -}}
tap "ankitpokhrel/jira-cli"
brew "jira-cli"
{{ end -}}

{{ if ne .machine_type "casual" -}}
brew "nushell"
{{ end -}}
```

**Injecting secrets** — fish config uses tokens without committing them:
```
{{ if .jira_api_token -}}
set -gx JIRA_API_TOKEN {{ .jira_api_token | quote }}
{{ end -}}

{{ if .cert_path -}}
set -gx SSL_CERT_FILE {{ .cert_path }}
set -gx NODE_EXTRA_CA_CERTS {{ .cert_path }}
{{ end -}}
```

**Architecture branching** — brew prefix differs on arm64 vs x86:
```
{{ if eq .chezmoi.arch "arm64" -}}
/opt/homebrew/bin/brew shellenv | source
{{ else -}}
/usr/local/bin/brew shellenv | source
{{ end -}}
```

The trailing `-` in `{{- ... -}}` trims whitespace — use it to avoid blank lines in output. Run `chezmoi cat <target>` to see the rendered result.

Available template variables (defined in `.chezmoi.toml.tmpl`):
- `.machine_type` — `"work"`, `"dev"`, or `"casual"`
- `.brew_prefix` — `/opt/homebrew` or `/usr/local`
- `.hostname` — machine hostname
- `.cert_path` — CA bundle path (work machines)
- `.jira_api_token` — JIRA token (work machines)
- `.tuna_activate_keycode`, `.tuna_activate_modifiers`, `.tuna_leader_keycode`, `.tuna_leader_modifiers` — Tuna hotkey carbon key codes
- `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.hostname` — built-in system info

To add a new template variable, add a `promptStringOnce` or `promptChoiceOnce` call in `.chezmoi.toml.tmpl` and a corresponding line in the `[data]` section. Users will be prompted on next `chezmoi init`.

### Run scripts

Scripts in the source root with `run_` prefixes execute during `chezmoi apply`. This repo uses three patterns:

**`run_onchange_` — re-run when watched content changes.** The script embeds a hash of the file it watches. When that file changes, the hash changes, the rendered script content changes, and chezmoi re-runs it.

Example — `run_onchange_01-install-brew-packages.sh.tmpl`:
```bash
#!/bin/bash
# Brewfile hash: {{ include "dot_Brewfile.tmpl" | sha256sum }}
set -euo pipefail
BREW_PREFIX="{{ .brew_prefix }}"
# ... installs Homebrew if missing, then runs brew bundle
```

The comment containing `{{ include "dot_Brewfile.tmpl" | sha256sum }}` is the trigger mechanism. When anything in the Brewfile template changes, the hash changes, and the script re-runs on next `chezmoi apply`. The same pattern is used for mise tools and fisher plugins:

- `run_onchange_01-install-brew-packages.sh.tmpl` watches `dot_Brewfile.tmpl`
- `run_onchange_02-install-mise-tools.sh.tmpl` watches `dot_config/mise/config.toml`
- `run_onchange_03-install-fisher-plugins.sh.tmpl` watches `dot_config/fish/fish_plugins`

The numeric prefix (`01-`, `02-`, `03-`) controls execution order — brew installs first (including mise itself), then mise tools, then fish plugins.

**`run_after_` — run after every apply.** The theme sync script runs after all files are deployed:

```bash
#!/bin/bash
# Apply current theme to all downstream configs via elvish
set -euo pipefail
eval "$({{ .brew_prefix }}/bin/brew shellenv)"
# ... syncs palette database, applies current theme
```

**`run_once_` — run exactly once.** Used for one-time setup like building SbarLua from source. Chezmoi tracks these by content hash in its state database. To force a re-run: `chezmoi state delete-bucket --bucket=scriptState`.

When creating a new run script:
1. Choose the right prefix for when it should execute
2. If it needs template variables (like `.brew_prefix`), give it a `.tmpl` suffix
3. If it should re-run on file changes, embed `{{ include "path/to/watched/file" | sha256sum }}` in a comment
4. Always start with `set -euo pipefail` and use `eval "$({{ .brew_prefix }}/bin/brew shellenv)"` if the script needs Homebrew-installed tools
5. Make it idempotent — it may run again if the user resets state or changes the watched file

### File prefixes

Chezmoi encodes target file attributes in source filenames:

- `dot_config/` → `.config/` — `dot_` becomes `.`
- `private_Library/` → `Library/` with 0700 perms — `private_` restricts access
- `executable_sketchybarrc.tmpl` → `sketchybarrc` with +x — `executable_` sets the bit
- Prefixes stack: `private_Application Support/` is both private and has spaces (literal)

### External files (`.chezmoiexternal.toml`)

Pull files from URLs without storing them in the repo. This repo uses it for the Helix editor runtime:

```toml
[".config/helix/runtime"]
    type = "archive"
    url = "https://github.com/helix-editor/helix/archive/refs/heads/master.tar.gz"
    stripComponents = 2
    include = ["helix-master/runtime/**"]
    refreshPeriod = "168h"
```

This extracts the runtime directory from the Helix source tarball every 7 days. To add another external dependency, add a new section with the target path as the key.

### Ignoring files (`.chezmoiignore`)

Patterns for target paths that chezmoi should not manage. This repo ignores:
- Repo metadata (`README.md`, `AGENTS.md`)
- Generated/runtime files (`colors.lua`, `colors.sh`, `themes.json`, `current-theme`)
- Plugin-managed files (fisher-installed fish functions like `_pure_*`, `bass.fish`)
- Machine-local state (`fish_variables`, `completions`)
- App state (Tuna clipboard history, Emacs package cache)

When adding a new app config, check whether it generates runtime state files that should be ignored.

## Applying changes and reloading services

After editing source files, deploy with `chezmoi apply` (all files) or `chezmoi apply <target>` (one file). Some apps need a nudge:

- **Ghostty**: picks up config changes live, no reload needed
- **Sketchybar**: `sketchybar --reload` (it runs as a brew service — never launch the binary directly)
- **AeroSpace**: auto-reloads on config change
- **Fish**: new shell sessions pick up changes; `source ~/.config/fish/config.fish` for the current session
- **Helix/Zed/Emacs**: restart the editor
- **Theme changes**: `elvish -c "use dotfiles/theme; theme:apply <name>"` to apply a new theme across all apps

## Debugging chezmoi issues

- **"I changed a file but nothing happened"**: probably edited the deployed file under `~/` instead of the source. Use `chezmoi source-path <target>` to find the right file.
- **Understanding the diff**: `chezmoi diff` shows what `apply` would write. Lines with `+` are what chezmoi wants to put on disk; lines with `-` are what's currently there.
- **Template debugging**: `chezmoi cat <target>` shows the rendered output. `chezmoi execute-template '{{ .machine_type }}'` tests expressions. `chezmoi data` dumps all available template variables.
- **Run script re-running unexpectedly**: the `run_onchange_` scripts embed content hashes — any change to the watched file (even whitespace) triggers a re-run.
- **Run script not re-running**: the hash hasn't changed. Check with `chezmoi diff` to see if the rendered script differs from what chezmoi last ran.
- **Generated files appearing in diff**: files like `colors.lua`, `colors.sh` are runtime artifacts managed by the theme pipeline. They're in `.chezmoiignore` and should never be committed or manually edited.
