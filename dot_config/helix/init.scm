;; Run at the top level right after helix.scm is required.
;; The editor context is bound to *helix.cx*.
(require (prefix-in helix. "helix/commands.scm"))
(require "helix/keymaps.scm")
(require "cogs/recentf.scm")
(require "cogs/file-tree.scm")
(require "helix-file-watcher/file-watcher.scm")
(require "splash.scm")

;; Runs in the background every 2 minutes, snapshotting open files to
;; .helix/recent-files.txt in the current working directory.
(recentf-snapshot)

;; Runs in the background, watching the working directory for external
;; changes and reloading affected buffers.
(spawn-watcher)

;;;;;;;;;;;;;;;;;;;;;;;;;; Keybindings ;;;;;;;;;;;;;;;;;;;;;;;

(keymap (global)
        (normal (space (f ":recentf-open-files")
                       (e ":create-file-tree")
                       (g ":create-gs-picker")
                       (t ":open-term"))))

(define scm-keybindings (hash "insert" (hash "ret" ':scheme-indent)))

;; Grab the existing global keybindings, then layer the .scm-file-only and
;; file-tree-only overrides on separate copies, so neither leaks into the
;; other's buffer.
(define standard-keybindings (deep-copy-global-keybindings))
(define file-tree-base (deep-copy-global-keybindings))

(merge-keybindings standard-keybindings scm-keybindings)
(merge-keybindings file-tree-base FILE-TREE-KEYBINDINGS)

(set-global-buffer-or-extension-keymap (hash "scm" standard-keybindings FILE-TREE file-tree-base))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(when (equal? (command-line) '("hx")) (show-splash))
