# Agent Instructions: Fix Literate Config Against Source Files (Single Module)

## Objective
Fix one module at a time in the current literate configuration (`~/dotfiles/emacs/.emacs.d/config.org`) to match the corresponding original source `.el` file in `~/.emacs.d.bak.20250730_192239/lisp/`. The AI translation was severely incomplete - most functionality is missing.

## Session Scope
**IMPORTANT: Process ONE module per session to avoid context window issues.**

Follow the loading order from the backed up init.el:
1. **jd-base.el** - Core settings and package management
2. **jd-ui.el** - Theme, fonts, and visual elements  
3. **jd-edit.el** - Evil mode foundation
4. **jd-evil-extensions.el** - Additional Evil packages
5. **jd-evil-keypad.el** - Evil Keypad with which-key
6. **jd-navigation.el** - Window, buffer, tab management
7. **jd-completion.el** - Vertico, Corfu, Consult, Marginalia
8. **jd-org.el** - Org-mode configuration
9. **jd-notes.el** - Denote configuration
10. **jd-dev.el** - Development tools
11. **jd-journal.el** - ADHD-friendly journaling
12. **jd-ai.el** - AI integration

## Background
The configuration was converted from individual `.el` module files to a single literate `config.org` file. **The AI translation was catastrophically incomplete** - an epic failure that lost 70-90% of the original functionality:

### Scale of the Translation Disaster
- **jd-themes.el**: ~400 lines reduced to ~50 lines (87% loss)
  - Missing: All theme collection management, sophisticated switching logic, fontaine integration, mode-specific fonts
  - Kept: Basic fontaine presets and simple toggle function
  
- **jd-evil-keypad.el**: ~150 lines reduced to ~30 lines (80% loss)  
  - Missing: Complete which-key integration, helper functions, documentation
  - Kept: Basic evil-keypad activation
  
- **jd-ai.el**: ~500+ lines reduced to ~0 lines (100% loss)
  - Missing: Everything - API key management, model configurations, all AI functions
  - Kept: Nothing
  
- **jd-journal.el**: ~400+ lines reduced to ~50 lines (87% loss)
  - Missing: All template definitions, custom functions, workflow logic
  - Kept: Basic package declarations

This level of data loss makes the current config.org essentially non-functional compared to the original modular configuration.

## Available Source Files
**Original Source Directory:** `~/.emacs.d.bak.20250730_192239/lisp/`

**Available Files:**
- `jd-ai.el` - AI integration (ChatGPT, GPTel, Copilot)
- `jd-base.el` - Core settings and package management  
- `jd-completion.el` - Completion frameworks (Vertico, Corfu, etc.)
- `jd-dev.el` - Development tools and tree-sitter
- `jd-edit.el` - Evil mode and editing configuration
- `jd-evil-extensions.el` - Evil mode packages and extensions
- `jd-evil-keypad.el` - Evil Keypad with which-key integration
- `jd-journal.el` - ADHD-friendly journaling system
- `jd-minimal-modeline.el` - Custom modeline implementation
- `jd-navigation.el` - Window, buffer, and tab management
- `jd-notes.el` - Denote configuration for note-taking
- `jd-org.el` - Org mode configuration with fonts and styling
- `jd-themes.el` - Theme management and Fontaine integration
- `jd-ui.el` - Visual interface and UI elements

**Target File:** `~/dotfiles/emacs/.emacs.d/config.org`

## Fix Methodology

### Step 1: Read Source File
1. Read the complete source `.el` file for the specified module
2. Note all functions, variables, configurations, and dependencies

### Step 2: Locate Current Section
1. Find the corresponding section in `config.org`
2. Note what exists vs what's missing

### Step 3: Replace Section Completely  
1. **REPLACE** the entire section with the complete source content
2. Preserve the literate documentation structure but include ALL code
3. Ensure proper org-mode tangling directives

### Critical Areas (Common Missing Elements)
1. **Complete function definitions** - Most custom functions are missing
2. **All configuration variables** - `defcustom`, `setq`, custom variables
3. **Package configurations** - Complete `:use-package` blocks with all options
4. **Keybinding definitions** - All `define-key`, global bindings, keymaps
5. **Which-key integrations** - Descriptions and help text
6. **Hook configurations** - All `add-hook` statements
7. **Integration logic** - Complex multi-package setups

## Output Format
Replace the entire section in config.org with:

1. **Proper org-mode headers** following existing pattern
2. **Complete literate documentation** explaining what each part does
3. **ALL source code** properly tangled to `lisp/jd-MODULE.el`
4. **Preserve org-mode structure** but include complete functionality

## Success Criteria
- Source file functionality 100% preserved in config.org
- All functions, variables, keybindings present
- Proper org-mode tangling directives
- Module works identically to source version