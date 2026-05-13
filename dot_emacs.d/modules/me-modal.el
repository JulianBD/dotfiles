;;; me-modal.el --- Modal editing via Hel (Helix emulation) -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Helix-style selection-first modal editing via the Hel package.
;;
;; In Normal state you get selection-based editing and multiple cursors.
;; In Insert state, standard Emacs keys work as usual.  Hel doesn't
;; touch C-x or C-c, so they're always available.
;;
;; This module also registers Hel's keybinding scopes with the contract
;; framework (me-contract), enabling users to define Hel-state-aware
;; keybindings in config/keybindings.json without writing Elisp.
;;
;; Registered scopes:
;;
;;   hel-state      — bind a key in a Hel state (normal, motion, insert)
;;                    globally.  Calls `hel-keymap-global-set'.
;;                    Required field: state (string or array of strings).
;;
;;   hel-state-mode — bind a key in a Hel state within a specific keymap.
;;                    Calls `hel-keymap-set'.
;;                    Required fields: state, keymap.
;;
;; Example keybindings.json entries:
;;
;;   { "key": "g o", "command": "consult-imenu",
;;     "scope": "hel-state", "state": "normal" }
;;
;;   { "key": "g o", "command": "org-open-at-point",
;;     "scope": "hel-state-mode", "state": "normal",
;;     "keymap": "org-mode-map" }

;;; Code:

;; Hel dependencies.
(use-package dash :ensure t :defer t)
(use-package s :ensure t :defer t)
(use-package avy :ensure t :defer t)
(use-package pcre2el :ensure t :defer t)

(use-package hel
  :ensure nil
  :vc (:url "https://github.com/anuvyklack/hel.git" :rev "main")
  :config
  (hel-set-initial-state 'markdown-ts-mode 'normal)
  :hook (after-init . hel-mode))

(use-package hel-leader
  :after hel
  :vc (:url "https://github.com/anuvyklack/hel-leader.git" :rev "main"))

(use-package hel-org
  :after hel
  :vc (:url "https://github.com/anuvyklack/hel-org.git" :rev "main"))

;; Scope registrations for the contract framework (hel-state,
;; hel-state-mode) live in me-scopes.el, which the generator
;; loads independently.  This module only loads hel itself.

(provide 'me-modal)
;;; me-modal.el ends here
