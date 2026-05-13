;;; me-dired.el --- File manager -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Dired configuration.  All built-in.

;;; Code:

(use-package dired
  :ensure nil
  :commands (dired)
  :hook
  ((dired-mode . dired-hide-details-mode)
   (dired-mode . hl-line-mode))
  :config
  (setq dired-dwim-target t)                    ; two-pane copy/move
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq dired-auto-revert-buffer #'dired-directory-changed-p)

  ;; macOS doesn't have GNU ls; use the built-in ls-lisp instead.
  (when (eq system-type 'darwin)
    (require 'ls-lisp)
    (setq ls-lisp-use-insert-directory-program nil)
    (setq ls-lisp-dirs-first t)))

(provide 'me-dired)
;;; me-dired.el ends here
