;;; me-editing.el --- Editing behavior -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Text editing, scrolling, search, and input behavior.
;; All built-in -- no packages.
;;
;; Variable values that change per-preference (indent-tabs-mode,
;; tab-width, fill-column, scroll-conservatively, scroll-margin) are
;; in config/editing.json → generated/me-generated-editing.el.

;;; Code:

;; --- Selection and deletion ---

(delete-selection-mode 1)

(setq kill-do-not-save-duplicates t)
(setq save-interprogram-paste-before-kill t)

;; --- Indentation and whitespace ---

(setq tab-always-indent 'complete)
(setq require-final-newline t)
(setq sentence-end-double-space nil)

(setq comment-multi-line t)
(setq comment-empty-lines t)

;; --- Scrolling ---

(setq scroll-preserve-screen-position t)
(setq scroll-error-top-bottom t)

(setq auto-window-vscroll nil)
(setq fast-but-imprecise-scrolling t)
(setq hscroll-margin 2)
(setq hscroll-step 1)

(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;; --- Search ---

(setq isearch-lazy-count t)
(setq lazy-count-prefix-format "(%s/%s) ")
(setq lazy-highlight-initial-delay 0)
(setq isearch-lax-whitespace t)
(setq search-whitespace-regexp ".*?")
(setq isearch-repeat-on-direction-change t)

;; --- Parens ---

(setq show-paren-when-point-inside-paren t)
(setq show-paren-when-point-in-periphery t)
(show-paren-mode 1)

(electric-pair-mode 1)

;; --- Undo ---

(setq undo-limit (* 4 160000))
(setq undo-strong-limit (* 4 240000))
(setq undo-outer-limit (* 4 24000000))

;; --- Misc editing ---

(setq next-line-add-newlines nil)
(setq set-mark-command-repeat-pop t)
(setq backward-delete-char-untabify-method 'hungry)
(setq word-wrap t)

(setq eval-expression-print-length nil)
(setq eval-expression-print-level nil)

;; --- Repeat mode (Emacs 28+) ---

(when (fboundp 'repeat-mode)
  (setq repeat-exit-timeout 5)
  (repeat-mode 1))

(provide 'me-editing)
;;; me-editing.el ends here
