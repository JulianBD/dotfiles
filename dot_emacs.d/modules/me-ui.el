;;; me-ui.el --- Visual appearance -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Themes, fonts, modeline, and display settings.

;;; Code:

;; --- Themes ---

;; Install theme packages.  Which theme to load is controlled by
;; config/appearance.json → generated/me-generated-appearance.el.
(use-package modus-themes
  :vc (:url "https://github.com/protesilaos/modus-themes.git" :rev "main"))
(use-package ef-themes
  :vc (:url "https://github.com/protesilaos/ef-themes.git" :rev "main"))
(use-package standard-themes
  :vc (:url "https://github.com/protesilaos/standard-themes.git" :rev "main"))
(use-package doric-themes
  :vc (:url "https://github.com/protesilaos/doric-themes.git" :rev "main"))

;; --- Fonts (fontaine) ---

;; Install fontaine.  Preset configuration is generated from
;; config/appearance.json → generated/me-generated-appearance.el.
(use-package fontaine
  :vc (:url "https://github.com/protesilaos/fontaine.git" :rev "main")
  :config
  (setq fontaine-latest-state-file
        (locate-user-emacs-file "fontaine-latest-state.eld"))
  (fontaine-mode 1))

;; --- Cursor ---

(blink-cursor-mode -1)

;; --- Modeline ---

(line-number-mode 1)
(column-number-mode 1)

;; --- Display ---

(setq uniquify-buffer-name-style 'forward)      ; src/init.el, not init.el<2>
(setq truncate-string-ellipsis "…")             ; single-char ellipsis
(setq x-underline-at-descent-line t)            ; underline below descenders
(setq indicate-buffer-boundaries 'left)         ; fringe markers at buffer edges
(setq display-time-default-load-average nil)    ; no load average in time display

(setq use-file-dialog nil)                      ; minibuffer, not OS file picker
(setq use-dialog-box nil)                       ; minibuffer, not OS dialogs

;; Line numbers in programming modes.
(setq display-line-numbers-width 3)             ; prevent gutter jitter
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Highlight current line in prog and text modes.
(add-hook 'prog-mode-hook #'hl-line-mode)
(add-hook 'text-mode-hook #'hl-line-mode)

;; Visual line wrapping for prose.
(add-hook 'text-mode-hook #'visual-line-mode)

;; --- Help ---

(setq help-window-select t)                     ; auto-focus help buffers

;; --- Window behavior ---

(setq switch-to-buffer-obey-display-actions t)  ; C-x b respects display rules

;; Don't pop up noisy buffers.
(add-to-list 'display-buffer-alist
             '("\\`\\*\\(Warnings\\|Compile-Log\\)\\*\\'"
               (display-buffer-no-window)
               (allow-no-window . t)))

;; --- Tab bar ---

(setq tab-bar-show 1)                           ; show only when >1 tab

;; --- Which-key (built-in from Emacs 30) ---

(use-package which-key
  :ensure t
  :hook (after-init . which-key-mode))

(provide 'me-ui)
;;; me-ui.el ends here
