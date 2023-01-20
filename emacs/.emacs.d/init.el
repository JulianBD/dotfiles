;; defaults
(setq inhibit-startup-message t)

(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode 10)

(menu-bar-mode -1)

(set-face-attribute 'default nil :font "Hack" :height 160)


;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
 (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
   (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("1fab98300b100a19010734a14c4bf9b6712ffc8b9e1d7eca35f837adeeabf740" "53585ce64a33d02c31284cd7c2a624f379d232b27c4c56c6d822eff5d3ba7625" "986cdc701d133f7c6b596f06ab5c847bebdd53eb6bc5992e90446d2ddff2ad9e" default))
 '(package-selected-packages '(command-log-mode use-package)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(use-package command-log-mode)

;; Install straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; org mode
(use-package org)
(use-package org-modern
  :config (global-org-modern-mode))

;; which-key
(use-package which-key
  :config
  (setq which-key-popup-type 'minibuffer)
  (which-key-mode))

;; smex
(use-package smex)

;; evil
(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init))
(use-package evil-org
  :init (evil-org-mode))

;; ivy & counsel
(use-package counsel)
(use-package ivy
  :init (ivy-mode))
(use-package all-the-icons-ivy-rich
  :config (setq all-the-icons-ivy-rich-icon t))
(use-package ivy-rich
  :init (ivy-rich-mode))

;; projectile
(use-package projectile)

;; neotree
(use-package neotree)

;; mood-line
(use-package mood-line
  :config
  (mood-line-mode))

;; modus-themes
(use-package modus-themes
  :init (load-theme 'modus-operandi-tinted))

;;; languages
;; shell
;; active Babel languages
(org-babel-do-load-languages 'org-babel-load-languages '((shell . t)))
;; go-mode
(use-package go-mode)
