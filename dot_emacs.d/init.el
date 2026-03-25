;;; init.el --- Julian's Emacs configuration -*- lexical-binding: t -*-

;; Copyright (c) 2025 Julian Dorsey

;;; Commentary:
;; This is a modular Emacs configuration that prioritizes:
;; - Clean, maintainable organization
;; - ADHD-friendly note capture
;; - Evil mode integration
;; - Modern completion framework

;;; Code:

(defvar jd--initial-gc-threshold gc-cons-threshold
  "Initial value of `gc-cons-threshold' at startup.")
(setq gc-cons-threshold 100000000)

(add-to-list 'load-path (expand-file-name "lisp"
                                         (file-name-directory load-file-name)))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(require 'use-package-ensure)

(setq use-package-always-ensure nil)

(defun jd--package-install-needed-p ()
  "Return t if we need to install packages (first run)."
  (not (file-exists-p (expand-file-name "package-installed" user-emacs-directory))))

(require 'jd-base)
(require 'jd-ui)
(require 'jd-minimal-modeline)
(require 'jd-edit)
(require 'jd-evil-extensions)
(require 'jd-evil-keypad)
(require 'jd-navigation)
(require 'jd-completion)
(require 'jd-org)
(require 'jd-notes)
(require 'jd-dev)
;; Load modular journal system
(require 'jd-journal-core)
(require 'jd-journal-templates)
(require 'jd-journal-ai)
(require 'jd-journal-keybindings)
;; Load AI module with error handling
(condition-case err
    (require 'jd-ai)
  (error (message "Warning: Could not load jd-ai module: %s" err)))

(setq custom-file (expand-file-name "etc/custom.el"
                                  (file-name-directory load-file-name)))
(when (file-exists-p custom-file)
  (load custom-file))

(setq gc-cons-threshold (or jd--initial-gc-threshold 800000))

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(jd-themes-default-theme 'modus-vivendi-tinted))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
