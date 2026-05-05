;;; me-defaults.el --- Sane defaults -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Built-in settings that fix surprising or unhelpful Emacs defaults.
;; No packages, no opinions about workflow.
;;
;; Simple variable values (use-short-answers, bookmark-save-flag, etc.)
;; are managed via config/defaults.json → generated/me-generated-defaults.el.
;; This file handles structural config: hooks, mode toggles, directory
;; setup, and settings not suited to JSON.

;;; Code:

;; --- Answers and prompts ---

(setq confirm-kill-emacs 'y-or-n-p)
(setq ring-bell-function #'ignore)

;; Prevent cursor from entering the prompt text.
(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;; --- Files and backups ---

(setq version-control t)
(setq kept-new-versions 5)
(setq kept-old-versions 5)
(setq delete-old-versions t)

;; Centralize backup and auto-save files.
(let ((backup-dir (locate-user-emacs-file "backups/"))
      (autosave-dir (locate-user-emacs-file "autosaves/")))
  (make-directory backup-dir t)
  (make-directory autosave-dir t)
  (setq backup-directory-alist `(("." . ,backup-dir)))
  (setq auto-save-file-name-transforms `((".*" ,autosave-dir t)))
  (setq auto-save-list-file-prefix (expand-file-name ".saves-" autosave-dir)))

(setq auto-save-include-big-deletions t)
(setq find-file-visit-truename t)
(setq load-prefer-newer t)

;; --- Autorevert ---

(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-avoid-polling t)
(setq auto-revert-check-vc-info t)
(global-auto-revert-mode 1)

;; --- History and session ---

(add-hook 'after-init-hook #'recentf-mode)

(setq save-place-limit 600)
(save-place-mode 1)

(setq savehist-additional-variables
      '(kill-ring mark-ring global-mark-ring search-ring))
(savehist-mode 1)

;; --- Security ---

(setq gnutls-verify-error t)
(setq tls-checktrust t)
(setq gnutls-min-prime-bits 3072)
(setq auth-sources '("~/.authinfo.gpg"))

;; --- Performance ---

(setq process-adaptive-read-buffering nil)
(setq auto-mode-case-fold nil)
(setq inhibit-compacting-font-caches t)
(setq redisplay-skip-fontification-on-input t)

;; --- Disabled/enabled commands ---

(dolist (cmd '(narrow-to-region narrow-to-page upcase-region downcase-region))
  (put cmd 'disabled nil))

(dolist (cmd '(overwrite-mode iconify-frame))
  (put cmd 'disabled t))

;; --- macOS ---

(when (eq system-type 'darwin)
  ;; mac-command-modifier is in config/defaults.json
  (setq mac-option-modifier nil)
  (setq ns-use-proxy-icon nil))

(provide 'me-defaults)
;;; me-defaults.el ends here
