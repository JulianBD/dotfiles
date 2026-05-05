;;; me-scopes.el --- Scope and prefix emitter registrations -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; This file registers all keybinding scopes and prefix emitters
;; with the contract framework.  It is loaded by the GENERATOR only
;; — never during normal Emacs startup.
;;
;; Scope emitters are pure templates: they return quoted sexps
;; containing package symbols (hel-keymap-global-set, keymap-set, etc.)
;; but never call those functions.  No packages need to be loaded
;; for this file to work.
;;
;; To add a new scope (e.g., for evil or meow):
;;
;;   (me-contract-register-scope 'evil-state
;;     :required-fields '(state)
;;     :emitter (lambda (entry)
;;                `(evil-define-key
;;                   ',(plist-get entry :state)
;;                   'global
;;                   (kbd ,(plist-get entry :key))
;;                   #',(plist-get entry :command))))
;;
;; Then add entries to config/keybindings.json:
;;   { "key": "g o", "command": "consult-imenu",
;;     "scope": "evil-state", "state": "normal" }

;;; Code:

(require 'me-contract)

;; ═══════════════════════════════════════════════════════════════════
;; Built-in Scopes (standard Emacs APIs, always available)
;; ═══════════════════════════════════════════════════════════════════

(me-contract-register-scope 'global
  :required-fields nil
  :emitter (lambda (entry)
             `(keymap-global-set ,(plist-get entry :key)
                                 #',(plist-get entry :command))))

(me-contract-register-scope 'mode
  :required-fields '(keymap)
  :emitter (lambda (entry)
             (let* ((km (plist-get entry :keymap))
                    (feature (intern (replace-regexp-in-string
                                      "-\\(mode-\\)?map\\'" ""
                                      (symbol-name km)))))
               `(with-eval-after-load ',feature
                  (keymap-set ,km ,(plist-get entry :key)
                              #',(plist-get entry :command))))))

;; ═══════════════════════════════════════════════════════════════════
;; Hel Scopes (Helix emulation via the `hel' package)
;; ═══════════════════════════════════════════════════════════════════
;;
;; These emit calls to hel-keymap-global-set and hel-keymap-set.
;; The hel package does NOT need to be loaded for this to work —
;; the emitters just produce quoted forms containing those symbols.
;; At Emacs startup, hel will be loaded by me-modal.el before the
;; generated keybindings file runs.

(me-contract-register-scope 'hel-state
  :required-fields '(state)
  :emitter (lambda (entry)
             `(hel-keymap-global-set
               :state ',(plist-get entry :state)
               ,(plist-get entry :key)
               #',(plist-get entry :command))))

(me-contract-register-scope 'hel-state-mode
  :required-fields '(state keymap)
  :emitter (lambda (entry)
             (let* ((km (plist-get entry :keymap))
                    (feature (intern (replace-regexp-in-string
                                      "-\\(mode-\\)?map\\'" ""
                                      (symbol-name km)))))
               `(with-eval-after-load ',feature
                  (hel-keymap-set ,km
                                  :state ',(plist-get entry :state)
                                  ,(plist-get entry :key)
                                  #',(plist-get entry :command))))))

;; ═══════════════════════════════════════════════════════════════════
;; Prefix Emitters
;; ═══════════════════════════════════════════════════════════════════
;;
;; Called for each labeled prefix node in the keybinding tree.
;; Emit code that teaches discoverability packages about prefix groups.

;; which-key: register prefix labels for popup display.
(me-contract-register-prefix-emitter
 (lambda (prefix label _ctx)
   `(when (fboundp 'which-key-add-key-based-replacements)
      (which-key-add-key-based-replacements ,prefix ,label))))

;; ═══════════════════════════════════════════════════════════════════
;; Appearance Generator
;; ═══════════════════════════════════════════════════════════════════
;;
;; Reads config/appearance.json and emits fontaine preset setup
;; and theme loading.  This is a composite generator — multiple
;; JSON fields combine into structured elisp output.
;;
;; JSON format:
;;   {
;;     "default-font": "Aporetic Sans Mono",
;;     "variable-pitch-font": "Aporetic Sans",
;;     "font-size": 160,
;;     "light-theme": "ef-reverie",
;;     "dark-theme": "ef-dream"
;;   }

(me-contract-register-generator 'appearance
  (lambda (gen-dir)
    (let ((json-file (expand-file-name "config/appearance.json"
                                        user-emacs-directory))
          (out-file (expand-file-name "me-generated-appearance.el" gen-dir)))
      (if (not (file-exists-p json-file))
          (message "me-contract: config/appearance.json not found — skipping")
      (let* ((data (me-contract--read-json json-file))
             (default-font (alist-get 'default-font data))
             (vp-font (alist-get 'variable-pitch-font data))
             (font-size (alist-get 'font-size data))
             (light-theme (intern (alist-get 'light-theme data)))
             (dark-theme (intern (alist-get 'dark-theme data))))
        (with-temp-file out-file
          (insert ";;; me-generated-appearance.el --- Generated from config/appearance.json -*- lexical-binding: t; no-byte-compile: t -*-\n")
          (insert ";; Generated by me-contract-generate — do not edit by hand.\n")
          (insert (format ";; Generated: %s\n\n;;; Code:\n\n"
                          (format-time-string "%Y-%m-%dT%H:%M:%S")))

          ;; Fontaine presets.
          (insert ";; Font presets via fontaine\n")
          (insert (pp-to-string
                   `(setq fontaine-presets
                          '((regular)
                            (large
                             :default-height ,(round (* font-size 1.25)))
                            (presentation
                             :default-height ,(round (* font-size 1.625)))
                            (t
                             :default-family ,default-font
                             :default-weight regular
                             :default-height ,font-size
                             :fixed-pitch-family ,default-font
                             :fixed-pitch-weight nil
                             :fixed-pitch-height 1.0
                             :variable-pitch-family ,vp-font
                             :variable-pitch-weight nil
                             :variable-pitch-height 1.0
                             :mode-line-active-family nil
                             :mode-line-active-height 0.9
                             :mode-line-inactive-family nil
                             :mode-line-inactive-height 0.9
                             :bold-family nil
                             :bold-weight bold
                             :italic-family nil
                             :italic-slant italic
                             :line-spacing nil)))))
          (insert "\n")
          (insert (pp-to-string
                   '(fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))))
          (insert "\n")

          ;; Theme.
          (insert ";; Theme — load dark by default, light available via M-x load-theme\n")
          (insert (pp-to-string
                   `(load-theme ',dark-theme :no-confirm-loading)))
          (insert "\n")

          ;; Provide convenient switching variables.
          (insert ";; Stash light/dark choices for programmatic switching\n")
          (insert (pp-to-string
                   `(defvar me-light-theme ',light-theme
                      "Light theme from config/appearance.json.")))
          (insert (pp-to-string
                   `(defvar me-dark-theme ',dark-theme
                      "Dark theme from config/appearance.json.")))
          (insert "\n")

          (insert "(provide 'me-generated-appearance)\n")
          (insert ";;; me-generated-appearance.el ends here\n"))
        (message "me-contract: generated me-generated-appearance"))))))

(provide 'me-scopes)
;;; me-scopes.el ends here
