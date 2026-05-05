# modular-emacs

Two artifacts in one repo. Strict separation of concerns.

## 1. Personal Emacs Config

Minimal, vanilla-biased. Emacs 30+. macOS (darwin).

### File layout

```
early-init.el          # GC tuning, UI suppression, frame setup
init.el                # Package bootstrap, module loading, generated file loading
modules/
  me-defaults.el       # Sane built-in defaults (answers, files, history, perf, macOS)
  me-editing.el        # Selection, scrolling, search, parens, undo, repeat-mode
  me-ui.el             # Theme packages, fontaine, which-key, display settings
  me-completion.el     # vertico, orderless, marginalia, consult, embark, corfu
  me-dired.el          # Dired config, ibuffer
  me-modal.el          # Hel (helix emulation) + hel-leader + hel-org
  me-writing.el        # markdown-mode, org-mode basics
  me-programming.el    # Eglot, treesitter, flymake, VC (exists, not loaded)
```

### How init.el works

1. Adds `modules/` and `generated/` to load-path
2. Bootstraps package.el with GNU, NonGNU, MELPA archives
3. Restores `file-name-handler-alist` and `vc-handled-backends` from early-init
4. Loads modules via `require` in dependency order
5. Loads generated config files (from `generated/`) at the end

### Conventions

- Module prefix: `me-` for module files, `me--` for internal vars
- `use-package` for package installation and structural config within modules
- Keybindings, variables, appearance managed via JSON → codegen (see below)
- Hooks, mode toggles, display-buffer rules stay in elisp (structural, rarely changes)

### Installed packages

Completion: vertico, orderless, marginalia, consult, embark, embark-consult, corfu
Modal: hel, hel-leader, hel-org (+ deps: dash, s, avy, pcre2el)
Themes: modus-themes, ef-themes, standard-themes, doric-themes
Fonts: fontaine
Writing: markdown-mode
UI: which-key, simple-httpd (for scraper dashboard)

### What's not wired in yet

- AI: gptel, minuet-ai, eca (discussed, not installed)
- PKM: ekg (discussed, not installed)
- me-programming.el exists but is commented out in init.el

---

## 2. Contract Framework (me-contract)

A **compiler** that turns JSON config into plain elisp. Development-time tool — never loaded at Emacs startup. The generated `.el` files are standalone, readable, and have zero dependency on the framework.

### Two-phase model

**Development time** (when you edit config):
```
config/*.json  →  me-contract-generate  →  generated/*.el
```

**Emacs startup** (every launch):
```
init.el  →  require 'me-generated-defaults
         →  require 'me-generated-editing
         →  require 'me-generated-appearance
         →  require 'me-generated-keybindings
```

### Running the generator

From a running Emacs (requires loading the framework interactively):
```
M-x me-contract-generate
```

From shell (no running Emacs needed):
```sh
emacs --batch \
  --eval '(setq user-emacs-directory "/path/to/modular-emacs/")' \
  --eval '(add-to-list (quote load-path) "modules")' \
  -l me-contract -l me-defaults-atoms -l me-scopes \
  -f me-contract-generate
```

### File layout

```
modules/
  me-contract.el         # The compiler: registries, validation, codegen
  me-defaults-atoms.el   # Variable atom registrations (schemas + defaults)
  me-scopes.el           # Scope emitters + prefix emitters + custom generators
config/
  defaults.json          # Variable values for me-defaults module
  editing.json           # Variable values for me-editing module
  appearance.json        # Font family, size, light/dark theme
  keybindings.json       # Keybinding tree (flat + nested, multiple scopes)
  scrape-rules.json      # Regex rules for the API scraper
generated/
  me-generated-defaults.el      # setq calls
  me-generated-editing.el       # setq/setq-default calls
  me-generated-appearance.el    # fontaine-presets + load-theme
  me-generated-keybindings.el   # keymap-global-set, keymap-set, hel-keymap-global-set
```

### Key concepts

**Atom types** — units of configuration. Currently: `variable` (setq/setq-default). Each type has an emitter that returns a quoted sexp.

**Scopes** — keybinding dispatch targets. Each scope has an emitter and required fields. Scopes are registered in `me-scopes.el`, not in the framework core.

Built-in scopes:
- `global` → emits `(keymap-global-set ...)`
- `mode` → emits `(with-eval-after-load ... (keymap-set ...))`

Package-registered scopes (in me-scopes.el):
- `hel-state` → emits `(hel-keymap-global-set :state ...)`
- `hel-state-mode` → emits `(with-eval-after-load ... (hel-keymap-set ...))`

**Prefix emitters** — called for labeled branch nodes in the keybinding tree. Currently registered: which-key label emitter.

**Custom generators** — for config that doesn't fit the variable atom pattern (e.g., appearance.json → fontaine presets + theme). Registered via `me-contract-register-generator`.

### Keybinding JSON format

Supports flat bindings and nested prefix trees, mixed freely:

```json
[
  { "prefix": "M-g", "label": "goto", "scope": "global",
    "bindings": [
      { "key": "g", "command": "consult-goto-line" },
      { "key": "o", "command": "consult-outline" }
    ]
  },
  { "key": "C-x C-b", "command": "ibuffer", "scope": "global" },
  { "key": "<tab>", "command": "corfu-complete",
    "scope": "mode", "keymap": "corfu-map" },
  { "prefix": "g", "label": "goto (hel)", "scope": "hel-state", "state": "normal",
    "bindings": [
      { "key": "o", "command": "consult-imenu" }
    ]
  }
]
```

Children inherit `scope`, `state`, `keymap` from parent nodes. Keys concatenate with spaces.

### Appearance JSON format

```json
{
  "default-font": "Aporetic Sans Mono",
  "variable-pitch-font": "Aporetic Sans",
  "font-size": 160,
  "light-theme": "ef-reverie",
  "dark-theme": "ef-dream"
}
```

### Adding a new scope

In `me-scopes.el`:
```elisp
(me-contract-register-scope 'evil-state
  :required-fields '(state)
  :emitter (lambda (entry)
             `(evil-define-key
                ',(plist-get entry :state)
                'global
                (kbd ,(plist-get entry :key))
                #',(plist-get entry :command))))
```

No changes to me-contract.el needed. The framework is package-agnostic.

### Validation

The generator validates at generation time (not runtime):
- Unknown atoms → error with name
- Type mismatches → error with expected vs got
- Unregistered scopes → error with hint about missing module
- Missing required fields → error naming the field
- Invalid key sequences → error showing the bad key

---

## 3. API Scraper

Walks installed packages, extracts every `def*` form with full metadata, and emits per-package org files with documentation.

### Running the scraper

```sh
emacs --batch --init-directory . \
  -l early-init.el -l init.el -l scrape-defs.el
```

Output: `scraped/*.org` — one file per package.

### What it extracts

- `defcustom`: name, default, `:type` spec, `:group`, `:set` presence, docstring
- `defun`/`defmacro`/`defsubst`: name, arglist, `(interactive)` spec, docstring
- `defface`: name, face spec, docstring
- `defvar-keymap`: name, parent, key→command binding table
- `define-minor-mode`: name, `:global`, `:lighter`, `:keymap`, docstring
- `defvar`/`defvar-local`/`defconst`: name, default, buffer-local/constant flags
- Package documentation: README, docs/*.org, *.md (converted via pandoc)

### Filtering

Controlled by `config/scrape-rules.json`:
```json
{
  "defaults": {
    "include": ["^{pkg}-", "^{pkg-base}-"],
    "exclude": ["--"]
  },
  "overrides": {
    "pcre2el": { "include": ["^rxt-", "^pcre-"] }
  }
}
```

`{pkg}` = package name, `{pkg-base}` = name with `-mode`/`-el` stripped.

### Web dashboard (legacy)

`scrape-serve.el` serves a filterable HTML view at localhost:8008. Uses simple-httpd. Predates the org output — still works but the org files are the primary output now.

---

## Design principles

- **Data, not code**: JSON files contain no computation. Symbol references only.
- **Codegen, not runtime magic**: generated files are plain elisp anyone can read.
- **Framework adds, never subtracts**: raw elisp config works unchanged alongside.
- **Package-agnostic**: the framework has zero knowledge of hel, evil, meow, etc. Package integrations register scopes in me-scopes.el.
- **Structural config stays in elisp**: hooks, mode toggles, use-package declarations, display-buffer-alist. Only frequently-changed values (variables, keybindings, appearance) go through JSON.
- **Scraper is for discovery, not automation**: it shows what packages expose. The user decides what to configure and how.
