;;; me-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; This is the one area where built-in completion is genuinely
;; inadequate.  vertico + orderless + corfu are lightweight, composable,
;; and extend (not replace) Emacs's completion API.
;;
;; marginalia is included for the annotations -- seeing a command's
;; docstring or a file's size in the minibuffer is a significant
;; usability improvement.

;;; Code:

;; --- Built-in completion settings ---

;; These apply regardless of which packages are loaded.
(setq completion-category-defaults nil)         ; start from clean slate
(setq completion-category-overrides nil)
(setq completion-cycle-threshold 1)             ; TAB cycles when few candidates

;; --- Minibuffer completion (vertico) ---

(use-package vertico
  :ensure t
  :hook (after-init . vertico-mode))

;; --- Completion annotations (marginalia) ---

(use-package marginalia
  :ensure t
  :hook (after-init . marginalia-mode))

;; --- Completion style (orderless) ---

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic)))

;; --- Enhanced commands (consult) ---

;; Drop-in replacements for built-in commands with live preview.
(use-package consult
  :ensure t
  :bind (("C-x b"   . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("M-g g"   . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o"   . consult-outline)
         ("M-g i"   . consult-imenu)
         ("M-s l"   . consult-line)
         ("M-s r"   . consult-ripgrep)
         ("M-s f"   . consult-find)
         ("M-y"     . consult-yank-pop)))

;; --- Contextual actions (embark) ---

;; Act on any completion candidate or thing at point.
(use-package embark
  :ensure t
  :bind (("C-."   . embark-act)
         ("C-;"   . embark-dwim)
         ("C-h B" . embark-bindings)))

;; Wire embark into consult for exportable search results.
(use-package embark-consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; --- Minibuffer history ---

(use-package savehist
  :ensure nil
  :hook (after-init . savehist-mode))

;; --- In-buffer completion (corfu) ---

(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind (:map corfu-map ("<tab>" . corfu-complete))
  :config
  (setq tab-always-indent 'complete)
  (setq corfu-preview-current nil)              ; don't insert before confirming
  (setq corfu-min-width 20)

  (setq corfu-popupinfo-delay '(1.25 . 0.5))
  (corfu-popupinfo-mode 1)

  ;; Rank candidates by usage history.
  (with-eval-after-load 'savehist
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(provide 'me-completion)
;;; me-completion.el ends here
