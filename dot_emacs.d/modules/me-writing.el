;;; me-writing.el --- Org-mode and Markdown -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Configuration for prose, notes, and PKM.
;; Functional settings only — no styling.

;;; Code:

;; --- Markdown ---

(use-package markdown-mode
  :ensure t
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :config
  (setq markdown-fontify-code-blocks-natively t))

;; --- Org ---

(use-package org
  :ensure nil
  :config
  ;; Navigation and editing.
  (setq org-return-follows-link t)
  (setq org-mouse-1-follows-link t)
  (setq org-catch-invisible-edits 'show-and-error)
  (setq org-special-ctrl-a/e t)
  (setq org-insert-heading-respect-content t)

  ;; Source blocks.
  (setq org-src-fontify-natively t)
  (setq org-src-tab-acts-natively t)
  (setq org-edit-src-content-indentation 0))

(provide 'me-writing)
;;; me-writing.el ends here
