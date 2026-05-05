;;; me-defaults-atoms.el --- Atom registrations for defaults -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Registers the configurable surface of me-defaults as atoms.
;; Each atom is tagged with :module 'defaults so the framework
;; knows which JSON file it belongs to (config/defaults.json).

;;; Code:

(require 'me-contract)

;; --- Answers and prompts ---

(me-defatom variable use-short-answers
  :module defaults :type boolean :default t
  :doc "Use y/n instead of yes/no for confirmation prompts")

(me-defatom variable enable-recursive-minibuffers
  :module defaults :type boolean :default t
  :doc "Allow opening a minibuffer while one is already active")

;; --- Files and backups ---

(me-defatom variable make-backup-files
  :module defaults :type boolean :default t
  :doc "Create backup files when saving")

(me-defatom variable backup-by-copying
  :module defaults :type boolean :default t
  :doc "Copy files to backup instead of renaming (preserves hard links)")

(me-defatom variable create-lockfiles
  :module defaults :type boolean :default nil
  :doc "Create .#file lock symlinks")

(me-defatom variable delete-by-moving-to-trash
  :module defaults :type boolean :default t
  :doc "Use OS trash instead of permanent deletion")

(me-defatom variable vc-follow-symlinks
  :module defaults :type boolean :default t
  :doc "Follow symlinks in version-controlled files without asking")

;; --- History and session ---

(me-defatom variable recentf-max-saved-items
  :module defaults :type natnum :default 300
  :doc "Maximum number of recent files to remember")

(me-defatom variable history-length
  :module defaults :type natnum :default 300
  :doc "Maximum number of minibuffer history entries to save")

(me-defatom variable bookmark-save-flag
  :module defaults :type integer :default 1
  :doc "Save bookmarks after every N changes (1 = immediate)")

;; --- Performance ---

(me-defatom variable read-process-output-max
  :module defaults :type natnum :default 2097152
  :doc "Max bytes to read from a process in one chunk (helps LSP)")

;; --- Editing ---

(me-defatom variable indent-tabs-mode
  :module editing :type boolean :default nil :buffer-local t
  :doc "Use tabs for indentation (nil = spaces)")

(me-defatom variable tab-width
  :module editing :type natnum :default 4 :buffer-local t
  :doc "Width of a tab character in columns")

(me-defatom variable fill-column
  :module editing :type natnum :default 80 :buffer-local t
  :doc "Column at which to wrap text")

(me-defatom variable scroll-conservatively
  :module editing :type natnum :default 10
  :doc "Lines from edge before Emacs recenters (higher = less aggressive)")

(me-defatom variable scroll-margin
  :module editing :type natnum :default 3
  :doc "Lines of margin to keep above/below cursor when scrolling")

;; --- macOS ---

(me-defatom variable mac-command-modifier
  :module defaults :type symbol :default 'meta
  :doc "What modifier the Command key maps to (meta, super, hyper, nil)")

(provide 'me-defaults-atoms)
;;; me-defaults-atoms.el ends here
