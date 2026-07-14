;;; Sensible defaults that are not too intrusive and focus on common use-cases.  By Protesilaos on 2026-04-30.

;; These are not all of my favourite options.  I am not even including
;; any of my packages.  They are just some basics that I consider
;; useful, given what I have learnt from my exchange with other people
;; of all skill levels.


;; Persist all customisations in a separate file called "custom.el".
;; It is in the same directory as the "init.el".
;;
;; Without the `custom-file', Emacs writes directly to the "init.el",
;; which can be confusing.
(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

(use-package package
  :ensure nil
  :config
  ;; MELPA only: elpa.gnu.org and elpa.nongnu.org are network-blackholed
  ;; here (TLS handshake hangs rather than failing), and since
  ;; package-refresh-contents is synchronous, any :ensure t install that
  ;; hits them freezes Emacs's main thread — which then freezes aerospace
  ;; and sketchybar too, since their AX queries into Emacs block on it.
  ;; Everything currently in this config resolves fine from MELPA alone;
  ;; packages that only live on GNU ELPA (e.g. ef-themes) are installed
  ;; via :vc from GitHub instead.
  (setq package-archives
        '(("melpa" . "https://melpa.org/packages/")))
  (setq url-queue-timeout 10))

;;;; General options
(use-package emacs
  :ensure nil
  :demand t
  :init
  (defun prot/keyboard-quit-dwim ()
    "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regular `keyboard-quit'."
    (interactive)
    (cond
     ((region-active-p)
      (keyboard-quit))
     ((derived-mode-p 'completion-list-mode)
      (delete-completion-window))
     ((> (minibuffer-depth) 0)
      (abort-recursive-edit))
     (t
      (keyboard-quit))))
  :bind
  ("C-g" . prot/keyboard-quit-dwim)
  :config
  ;; Set your favourite font family and height here.  The :height is
  ;; 10x the point size you most commonly find on other applications.
  (set-face-attribute 'default nil :family "Aporetic Sans Mono" :height 160)
  ;; Set your favourite font for elements that are designed to always
  ;; be monospaced.  The height SHOULD BE a floating point, which is
  ;; interpreted as relative to the `default'.
  (set-face-attribute 'fixed-pitch nil :family "Aporetic Serif Mono" :height 1.0)
  ;; Same as above for proportionately spaced elements.  Make any
  ;; buffer proportionately spaced by enabling the `variable-pitch-mode'.
  ;;
  ;; [ NOTE: If you use the Modus themes or derivatives, set
  ;;   `modus-themes-mixed-fonts', load the theme for the option to
  ;;   take effect, and then enable `variable-pitch-mode':
  ;;   spacing-sensitive elements like Org tables and code blocks will
  ;;   remain monospaced. ]
  (set-face-attribute 'variable-pitch nil :family "Aporetic Sans" :height 1.0)

  ;; I have never seen a user say "no" to loading a theme they have
  ;; downloaded.  Technically, any Elisp file can run arbitrary code,
  ;; so this is not doing much on the security front.
  (setq custom-safe-themes t)
  (setq use-short-answers t)
  (setq read-answer-short t)
  (setq help-window-select t) ; also check `display-buffer-alist' below
  (setq help-window-keep-selected t) ; Emacs 29
  (setq find-library-include-other-files nil) ; Emacs 29
  (setq window-combination-resize t)
  (setq save-interprogram-paste-before-kill t)
  ;; Do not jump to the current line in `*occur*' buffers.  The reason
  ;; is that you are already on that line: you want to do `occur' to
  ;; get more than that (and, presumably, to do something with the
  ;; results such as to edit them with `occur-edit-mode').
  (setq list-matching-lines-jump-to-current-line nil)
  (setq completion-category-defaults nil))

;;;; Save minibuffer histories
(use-package savehist
  :ensure nil
  :config
  (savehist-mode 1))

;;;; Delete the selected text when inserting new text
(use-package delsel
  :ensure nil
  :config
  (delete-selection-mode 1))

;;;; Bookmarks
(use-package bookmark
  :ensure nil
  :config
  ;; Emacs 29 displays a bookmark icon on the fringe.  Many people
  ;; have asked me what that thing is.  I also think it is confusing.
  (setq bookmark-fringe-mark nil)
  ;; Write changes to the bookmark file as soon as 1 modification is
  ;; made (addition or deletion).  Otherwise Emacs will only save the
  ;; bookmarks when it closes, which may never happen properly
  ;; (e.g. power failure).
  (setq bookmark-save-flag 1))

;;;; Dired
(use-package dired
  :ensure nil
  :config
  ;; Most people I have talked to prefer a single Dired buffer.
  ;; Personally I like the many Dired buffers, but I understand why
  ;; this feels overwhelming.
  (setq dired-kill-when-opening-new-dired-buffer t)
  (setq dired-auto-revert-buffer #'dired-directory-changed-p) ; also see `dired-do-revert-buffer'
  (setq dired-clean-up-buffers-too t)
  (setq dired-clean-confirm-killing-deleted-buffers t)
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq delete-by-moving-to-trash t)
  (setq dired-create-destination-dirs 'ask)
  (setq dired-create-destination-dirs-on-trailing-dirsep t) ; Emacs 29
  (setq wdired-create-parent-directories t))

;;;; Isearch
(use-package isearch
  :ensure nil
  :config
  ;; ;; Enable those to make "package install" match those words with
  ;; ;; anything in between.  I think this is the single best tweak I
  ;; ;; ever made.
  ;;
  ;; (setq search-whitespace-regexp ".*?")
  ;; (setq isearch-lax-whitespace t)
  ;; (setq isearch-regexp-lax-whitespace nil)
  (setq isearch-lazy-count t)
  (setq lazy-count-prefix-format "(%s/%s) ")
  (setq lazy-count-suffix-format nil))

;;;; Diff
(use-package diff
  :ensure
  :config
  ;; You cannot expect the syntax highlighting of themes to look
  ;; equally readabable against what typically are red and green
  ;; backgrounds.  This should be opt-in by default, not opt-out.
  (setq diff-font-lock-syntax nil))

;;;; Ediff
(use-package ediff
  :ensure nil
  :config
  ;; Ediff is virtually unusable without those.  Especially on tiling
  ;; window managers.  But even on a regular desktop environment it is
  ;; confusing and cumbersome to have the control panel in another
  ;; frame.
  (setq ediff-split-window-function 'split-window-horizontally)
  (setq ediff-window-setup-function 'ediff-setup-windows-plain))

;;;; SHR
(use-package shr
  :ensure nil
  :config
  ;; t is bad for accessibility and generally awkward for HTML email
  ;; (especially with dark themes).
  (setq shr-use-colors nil)
  ;; This option should not exist, given `variable-pitch-mode'.
  ;; Furthermore, its default value runs counter to almost everything
  ;; else in Emacs which just uses the `default' face.
  (setq shr-use-fonts nil))

;;;; Control the display of common ancillary windows

;; Always focus common ancillary windows.  Place them in a window
;; already occupied by their respective major mode or below the
;; current window.
(add-to-list 'display-buffer-alist
             '((or . ((derived-mode . occur-mode)
                      (derived-mode . grep-mode)
                      (derived-mode . Buffer-menu-mode)
                      (derived-mode . log-view-mode)
                      (derived-mode . help-mode)))
               (display-buffer-reuse-mode-window display-buffer-below-selected)
               (body-function . select-window)))

(add-to-list 'display-buffer-alist
             '("\\`\\*\\(Org \\(Select\\|Note\\)\\|Agenda Commands\\)\\*\\'" ; the `org-capture' key selection, `org-add-log-note', and agenda dispatcher
               (display-buffer-in-side-window)
               (dedicated . t)
               (side . bottom)
               (slot . 0)
               (window-parameters . ((mode-line-format . none)))))

(add-to-list 'display-buffer-alist
             '((derived-mode . calendar-mode)
               (display-buffer-reuse-mode-window display-buffer-below-selected)
               (mode . (calendar-mode bookmark-edit-annotation-mode ert-results-mode))
               (inhibit-switch-frame . t)
               (dedicated . t)
               (window-height . fit-window-to-buffer)))

(add-to-list 'display-buffer-alist
             '((derived-mode . reb-mode) ; M-x re-builder
               (display-buffer-reuse-mode-window display-buffer-below-selected)
               (inhibit-switch-frame . t)
               (window-height . 4) ; note this is literal lines, not relative
               (dedicated . t)
               (preserve-size . (t . t))))

;;;; ESSENTIAL packages to install

(use-package vertico
  :ensure t
  :config
  (vertico-mode 1))

(use-package marginalia
  :ensure t
  :config
  (marginalia-mode 1))

;;;; VERY USEFUL but not essential packages
(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic)))

(use-package consult
  :ensure t
  ;; All commands have their utility, but those are commonly needed.
  :commands (consult-buffer consult-line consult-outline consult-find consult-grep))

(use-package embark
  :ensure t
  :bind
  ;; Embark is helpful in every context, though there are other ways
  ;; to do what it does.  Where it stands out is in its ability to
  ;; deal with all the minibuffer results.  The equivalent of those
  ;; two commands should be a core Emacs functionality.
  ( :map minibuffer-local-map
    ("C-c C-c" . embark-collect)
    ("C-c C-e" . embark-export))
  :config
  ;; Needed for correct exporting while using Embark with Consult commands.
  (use-package embark-consult
    :ensure t
    :after consult))

;; Useful when combined with `delete-by-moving-to-trash'.
(use-package trashed
  :ensure t)

;;;;; NON-ESSENTIAL packages

(use-package ultra-scroll
  :ensure t
  :init
  (setq scroll-conservatively 3 ; or whatever value you prefer, since v0.4
        scroll-margin 0)        ; important: scroll-margin>0 not yet supported
  :config
  (ultra-scroll-mode 1))

;; Themes. Installed from GitHub via :vc because ef-themes lives only on
;; GNU ELPA and the corporate network black-holes TLS to elpa.gnu.org /
;; elpa.nongnu.org (it is not on MELPA).
(use-package ef-themes
  :ensure t
  :vc (:url "https://github.com/protesilaos/ef-themes.git" :rev :newest))

;; Dependencies
(use-package dash :ensure t)
(use-package avy :ensure t)
(use-package pcre2el :ensure t)
(use-package ultra-scroll :ensure t)

(use-package hel
  :ensure t
  :vc (:url "https://github.com/anuvyklack/hel.git" :rev "main")
  :custom (inhibit-startup-screen t)
  :config (hel-mode))

(use-package hel-leader
  :ensure t
  :vc (:url "https://github.com/anuvyklack/hel-leader.git" :rev "main")
  :after org)

(use-package hel-org
  :ensure t
  :vc (:url "https://github.com/anuvyklack/hel-org.git" :rev "main")
  :after org)

(use-package ghostel
  :ensure t)

(use-package hel-ghostel
  :ensure t
  :vc (:url "https://github.com/anuvyklack/hel-ghostel.git" :rev "main")
  :after (ghostel hel))

(use-package nael
  :ensure t
  :hook
  ((nael-mode . abbreve-mode)
   (nael-mode . eglot-ensure)))
  
