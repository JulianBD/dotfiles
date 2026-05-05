;;; me-programming.el --- Programming support -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; prog-mode hooks, Eglot (built-in LSP), and treesitter.
;; All built-in from Emacs 29+.

;;; Code:

;; --- prog-mode hooks ---

(add-hook 'prog-mode-hook #'subword-mode)       ; camelCase-aware navigation

;; --- Eglot (built-in LSP client, Emacs 29+) ---

(use-package eglot
  :ensure nil
  :defer t
  :config
  (setq eglot-sync-connect 0)                   ; async connection
  (setq eglot-autoshutdown t)                   ; kill server when last buffer closes
  (setq eglot-extend-to-xref t)                 ; LSP works in xref-navigated files
  (setq eglot-events-buffer-config '(:size 0))) ; no protocol log

;; --- Treesitter (Emacs 29+) ---

;; Remap traditional modes to treesitter equivalents when grammars are
;; installed.  Add entries as you install grammars.
(when (treesit-available-p)
  (setq major-mode-remap-alist
        '((bash-mode       . bash-ts-mode)
          (c-mode          . c-ts-mode)
          (c++-mode        . c++-ts-mode)
          (css-mode        . css-ts-mode)
          (js-mode         . js-ts-mode)
          (json-mode       . json-ts-mode)
          (python-mode     . python-ts-mode)
          (yaml-mode       . yaml-ts-mode))))

;; --- Compilation ---

(setq compilation-ask-about-save nil)            ; auto-save before compile
(setq compilation-always-kill t)                 ; kill old compile on rerun
(setq compilation-scroll-output 'first-error)    ; stop scrolling at first error
(setq comint-prompt-read-only t)                 ; read-only shell prompts
(setq ansi-color-for-comint-mode t)              ; render ANSI colors in shell output

;; --- Flymake ---

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode))

;; --- Version control ---

(setq vc-handled-backends '(Git))               ; only probe Git, not SVN/CVS/Hg
(setq vc-git-diff-switches '("--histogram"))    ; better diff algorithm
(setq vc-git-print-log-follow t)                ; follow renames in log

;; Ediff in same frame, not a separate one.
(setq ediff-window-setup-function #'ediff-setup-windows-plain)

(provide 'me-programming)
;;; me-programming.el ends here
