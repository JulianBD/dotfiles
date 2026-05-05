;;; init.el --- Main entry point -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Bootstraps packages and loads modules in dependency order.
;; This file is the bill of materials for the config.

;;; Code:

;; --- Load path ---

(add-to-list 'load-path
             (expand-file-name "modules" user-emacs-directory))

;; --- Package management ---

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

;; Prefer official archives over MELPA when a package exists in both.
(setq package-archive-priorities
      '(("gnu"    . 3)
        ("nongnu" . 2)
        ("melpa"  . 1)))

(package-initialize)

;; Restore early-init startup overrides now that package.el is ready.
(setq file-name-handler-alist me--file-name-handler-alist
      vc-handled-backends me--vc-handled-backends)

;; Bootstrap use-package on Emacs < 29 (built-in from 29 onward).
(when (< emacs-major-version 29)
  (unless (package-installed-p 'use-package)
    (unless package-archive-contents
      (package-refresh-contents))
    (package-install 'use-package)))

;; --- Custom file ---

;; Keep custom-set-variables out of init.el.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;; --- Modules ---

(require 'me-defaults)
(require 'me-editing)
(require 'me-ui)
(require 'me-completion)
(require 'me-dired)
(require 'me-modal)
(require 'me-writing)
;; (require 'me-programming)
;; (require 'me-ai)

;; --- Generated configuration ---
;;
;; These files are produced by `M-x me-contract-generate' from
;; the JSON files in config/.  They contain plain setq, keymap-global-set,
;; etc. — no framework dependency at load time.
;; Edit config/*.json, then regenerate.  Do not edit generated/*.el by hand.
(add-to-list 'load-path
             (expand-file-name "generated" user-emacs-directory))
(require 'me-generated-defaults)
(require 'me-generated-editing)
(require 'me-generated-appearance)
(require 'me-generated-keybindings)

(provide 'init)
;;; init.el ends here
