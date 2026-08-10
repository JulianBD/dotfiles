;;; init.el -*- lexical-binding: t; no-byte-compile: t; -*-

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

;; Log native-comp warnings to *Warnings* without popping it open (nil = drop, t = pop-ups).
(setq native-comp-async-report-warnings-errors 'silent)

;;;; Patches for upstream bugs
;;
;; Workarounds for third-party package bugs live in "patches.el", written
;; with el-patch so each one stays a verifiable diff against upstream
;; rather than a silent redefinition. After upgrading packages, run
;; `M-x el-patch-validate-all' -- it re-reads the installed sources and
;; reports any patch whose original no longer matches, which is the signal
;; that the bug was fixed (delete the patch) or the function was rewritten
;; (rewrite the patch).
(use-package el-patch
  :ensure t
  :demand t
  :config
  (load (locate-user-emacs-file "patches.el") nil :nomessage))

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
  ;;
  ;; Fira Code keeps its programming ligatures (=>, ->, etc.) in calt,
  ;; on by default, so no "Frozen"-style special build is needed --
  ;; ligature.el (below) handles composition and the font does the rest.
  (set-face-attribute 'default nil :family "FiraCode Nerd Font" :height 160)
  ;; Set your favourite font for elements that are designed to always
  ;; be monospaced.  The height SHOULD BE a floating point, which is
  ;; interpreted as relative to the `default'.
  (set-face-attribute 'fixed-pitch nil :family "FiraCode Nerd Font" :height 1.0)
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

;;;; Visual ergonomics for editing text

;; Centre prose in a readable column. text-mode only (covers org + markdown), not code.
(use-package olivetti
  :ensure t
  :hook (text-mode-hook . olivetti-mode)
  :custom
  (olivetti-body-width 80))

;; Highlight the line point is on.
(use-package hl-line
  :ensure nil
  :config
  (global-hl-line-mode 1))

;; Wrap at word boundaries instead of the default mid-character break.
(use-package simple
  :ensure nil
  :config
  (global-visual-line-mode 1)
  ;; Treat ". " as a sentence end so M-q / M-a / M-e handle single-spaced prose.
  (setq sentence-end-double-space nil))

;; Align wrapped continuation lines under the text they continue (Emacs 30+).
(use-package emacs
  :ensure nil
  :config
  (global-visual-wrap-prefix-mode 1))

;; Reopen a file at the position you left it.
(use-package saveplace
  :ensure nil
  :config
  (save-place-mode 1))

;; Show an offscreen opening delimiter in an overlay.
(use-package paren
  :ensure nil
  :config
  (setq show-paren-context-when-offscreen 'overlay)
  (setq show-paren-delay 0))

;; Strip down buffers with very long lines (minified JS, JSON dumps) to stay responsive.
(use-package so-long
  :ensure nil
  :config
  (global-so-long-mode 1))

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

(use-package flexoki-themes
  :ensure t
  :custom
  (flexoki-themes-use-bold-keywords t)
  (flexoki-themes-use-bold-builtins t)
  (flexoki-themes-use-italic-comments t))

;; Ligatures, for the default face's Fira Code (see above).
;; https://github.com/mickeynp/ligature.el
(use-package ligature
  :ensure t
  :config
  ;; The canonical Fira Code list from the ligature.el README. The font
  ;; carries the ligature glyphs in calt; this list only tells Emacs
  ;; which character sequences to compose into one glyph cluster so
  ;; cursor movement and selection behave correctly.
  (ligature-set-ligatures
   'prog-mode
   '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
     ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
     "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
     "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
     "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
     "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
     "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
     "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
     ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
     "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
     "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
     "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
     "\\\\" "://"))
  (global-ligature-mode t))

;; Dependencies
(use-package dash :ensure t)
(use-package avy :ensure t)
(use-package pcre2el :ensure t)
(use-package ultra-scroll :ensure t)
(use-package s :ensure t)

;; Hel and friends now live in the helheim-emacs org (moved from
;; anuvyklack/*). None of them are on MELPA yet -- there is no recipe in
;; melpa/recipes and nothing in archive-contents -- so they come from
;; GitHub via :vc.
;;
;; Pinned, NOT tracking main. Commit 560d4b0 (2026-07-14, "wip(integration):
;; move keys to `hel-collection' package") ripped the keybindings for
;; compile / grep / wgrep / occur / xref / diff / calendar / corfu /
;; consult / embark / dired out of hel-integration.el and into a separate
;; hel-collection package. That package exists but is 8 days old, has no
;; tags, and ships no dired module -- so main is mid-migration and leaves
;; several modes with no bindings at all.
;;
;; e2c818d is the last commit before that split: every integration still
;; in-tree, and it already contains the fixes that matter (93c88d8
;; "multiple cursors keys are lost on major mode change" and the scroll
;; fixes). It is 3 commits behind main, two of them cosmetic.
;;
;; Revisit once hel-collection stabilises and grows a dired module; then
;; this becomes :rev "main" plus a hel-collection use-package calling
;; (hel-collection-init) -- registered BEFORE the other hel packages, since
;; it only installs `with-eval-after-load' forms and Emacs runs those in
;; registration order.
(use-package hel
  :ensure t
  :vc (:url "https://github.com/helheim-emacs/hel.git"
       :rev "e2c818d91d6d27328f63b59d3193e71fa9d5b36b")
  :custom (inhibit-startup-screen t)
  :config (hel-mode))

;; Required by hel-leader, which drives which-key's internals to draw its preview (Emacs 30+).
(use-package which-key
  :ensure nil
  :config
  ;; Also governs hel-leader's preview delay.
  (setq which-key-idle-delay 0.5)
  (which-key-mode 1))

(use-package hel-leader
  :ensure t
  :vc (:url "https://github.com/helheim-emacs/hel-leader.git" :rev "main")
  :after hel)

(use-package hel-org
  :ensure t
  :vc (:url "https://github.com/helheim-emacs/hel-org.git" :rev "main")
  :after (hel org))

(use-package ghostel
  :ensure t
  :custom
  ;; Store the native module outside the elpa tree so package upgrades don't delete it.
  (ghostel-module-directory (locate-user-emacs-file "ghostel/"))
  ;; Download the pre-built binary (compiling needs Zig, not installed here).
  (ghostel-module-auto-install 'download))

(use-package hel-ghostel
  :ensure t
  :vc (:url "https://github.com/helheim-emacs/hel-ghostel.git" :rev "main")
  :after (ghostel hel))

;;;; Markdown
;;
;; `markdown-ts-mode' ships with Emacs 31 (lisp/textmodes/markdown-ts-mode.el)
;; but is wired up to exactly nothing: it has no autoload cookie, it never
;; touches `auto-mode-alist', and it is absent from
;; `treesit-major-mode-remap-alist' -- so `treesit-enabled-modes' does not
;; reach it either (that option only remaps legacy modes to ts modes, and
;; there is no built-in legacy markdown-mode to remap from). Hence the
;; explicit :mode below; without it ".md" opens in Fundamental mode.
;;
;; It needs TWO grammars, `markdown' and `markdown-inline' -- block
;; structure and inline structure are separate parsers. Both are already
;; installed under "tree-sitter/" here. The mode file registers their
;; `treesit-language-source-alist' recipes itself (pinned to commit
;; 413285231, both from the same repo but different :source-dir), so
;; `M-x markdown-ts-mode-install-parsers' is all that is needed on a new
;; machine -- with a prefix argument it also grabs html, yaml and toml,
;; which markdown-ts-mode uses for embedded code blocks and for YAML/TOML
;; frontmatter.
(use-package markdown-ts-mode
  :ensure nil ; built in
  :mode (("\\.md\\'" . markdown-ts-mode)
         ("\\.markdown\\'" . markdown-ts-mode)))

(use-package nael
  :ensure t
  :hook
  ((nael-mode . abbrev-mode)
   (nael-mode . eglot-ensure)))

(use-package gptel
  :ensure t
  ;; :vc ( :url "https://github.com/karthink/gptel.git" :rev "master")
  :config
  ;; Uses the default `authorization-code' login method. Upstream's
  ;; redirect_uri is double-encoded and OpenAI rejects it before any
  ;; account is involved; see the gptel section of "patches.el" for the
  ;; el-patch that fixes it. The `device' method is unaffected by that bug
  ;; but is not enabled on this account.
  (setq gptel-model 'gpt-5.4-mini
      gptel-backend (gptel-make-openai-oauth "ChatGPT-Enterprise")))

(use-package gptel-agent
  :ensure t
  ;; :vc ( :url "https://github.com/karthink/gptel-agent" :rev "master")
  :config (gptel-agent-update)
  :after gptel)         ;Read files from agents directories

(use-package vulpea
  :ensure t
  :init
  (setq vulpea-db-async-extraction 'full)
  (setq vulpea-db-parse-method 'single-temp-buffer)
  (setq vulpea-db-index-plain-links nil)
  :config
  (vulpea-db-autosync-mode +1)
  :after org)

(use-package vulpea-ui
  :ensure t
  :init
  (setq vulpea-ui-sidebar-position 'right)
  (setq vulpea-ui-sidebar-size 0.33)
  (setq vulpea-ui-outline-max-depth 3)
  (setq vulpea-ui-schema-health-ok-glyph "✓")
  (setq vulpea-ui-schema-health-issure-glyph "✗")
  (setq vulpea-ui-schema-health-bullet "●")
  (setq vulpea-ui-backlinks-show-preview t)
  (setq vulpea-ui-backlinks-prose-chars-before 30)
  (setq vulpea-ui-backlinks-prose-chars-after 50))

(use-package vulpea-journal
  :ensure t
  :init
  (setq vulpea-journal-ui-created-today-exclude-journal nil)
  :config
  (vulpea-journal-setup)
  (setq vulpea-journal-default-template
	(vulpea-journal-template-daily))
  :after (vulpea vulpea-ui))

(use-package consult-vulpea
  :ensure t
  :config
  (consult-vulpea-mode 1)
  :after vulpea)

(use-package embark-vulpea
  :vc (:url "https://github.com/fabcontigiani/embark-vulpea" :rev "main")
  :after (embark vulpea))

;; opencode's deps (plz -> plz-media-type -> plz-event-source) are GNU-ELPA-only,
;; so :vc from GitHub. Order matters: package-vc resolves each against what's installed.
(use-package plz
  :vc (:url "https://github.com/alphapapa/plz.el" :rev :newest))

(use-package plz-media-type
  :vc (:url "https://github.com/r0man/plz-media-type" :rev :newest)
  :after plz)

(use-package plz-event-source
  :vc (:url "https://github.com/r0man/plz-event-source" :rev :newest)
  :after plz-media-type)

(use-package opencode
  :vc (:url "https://codeberg.org/sczi/opencode.el.git" :rev :newest)
  :after (plz plz-event-source magit markdown-mode))

(use-package pi-coding-agent
  :ensure t
  :init
  (defalias 'pi 'pi-coding-agent))

;; Non-empty placeholder key; Ollama ignores it but minuet refuses to send without one.
(defun prot/minuet-ollama-api-key ()
  "Return a placeholder API key for the local Ollama server."
  "ollama")

;; Minuet code completion, backed by a local Ollama server.
(use-package minuet
  :ensure t
  ;; No bindings by request; commands are M-x only (minuet-active-mode-map is empty upstream).
  :hook (prog-mode-hook . minuet-auto-suggestion-mode)
  :config
  ;; qwen3.5 is a chat model, so use the chat-completions provider, not the FIM default.
  (setq minuet-provider 'openai-compatible)

  ;; Tuned down for local inference (raise context once you see how the 9b model performs).
  (setq minuet-n-completions 1
        minuet-context-window 512
        minuet-request-timeout 5)

  ;; plist-put, not setq: the plist also holds the prompt/fewshot/chat-input templates.
  (plist-put minuet-openai-compatible-options
             :end-point "http://localhost:11434/v1/chat/completions")
  (plist-put minuet-openai-compatible-options
             :api-key #'prot/minuet-ollama-api-key)
  (plist-put minuet-openai-compatible-options
             :model "qwen3.5:9b-mlx")

  ;; Disable reasoning. qwen3.5 is a thinking model; left on, it spends the whole
  ;; max_tokens budget inside <think> and emits no completion (13s, empty). Off: ~0.3s.
  (minuet-set-optional-options minuet-openai-compatible-options :reasoning_effort "none")

  ;; Cap output; completions are short.
  (minuet-set-optional-options minuet-openai-compatible-options :max_tokens 256)
  (minuet-set-optional-options minuet-openai-compatible-options :top_p 0.9))

;; Minimal modeline (replaces punch-line). Unmaintained since 2022 but works on Emacs 31.
(use-package simple-modeline
  :ensure t
  :hook (after-init-hook . simple-modeline-mode)
  :custom
  ;; (LEFT RIGHT). Dropped minor-modes/input-method/eol/encoding; add back
  ;; simple-modeline-segment-minor-modes for flycheck's error counts.
  (simple-modeline-segments
   '((simple-modeline-segment-modified
      simple-modeline-segment-buffer-name
      simple-modeline-segment-position)
     (simple-modeline-segment-misc-info
      simple-modeline-segment-vc
      simple-modeline-segment-process
      simple-modeline-segment-major-mode))))

(use-package flycheck
  :ensure t
  :hook
  (after-init-hook . global-flycheck-mode))

(use-package flyover
  :ensure t
  :hook ((flycheck-mode . flyover-mode)
         (flymake-mode . flyover-mode))
  :after flycheck
  :custom
  ;; Checker settings
  (flyover-checkers '(flycheck flymake))
  (flyover-levels '(error warning info))

  ;; Appearance. Despite the name, this only affects the icon background;
  ;; the message background comes from prot/flyover-sync-faces below.
  (flyover-use-theme-colors t)

  ;; Keep message text at full accent strength (upstream washes it toward white).
  (flyover-text-tint nil)

  ;; Icons
  (flyover-info-icon " ")
  (flyover-warning-icon " ")
  (flyover-error-icon " ")

  ;; Border styles: none, pill, arrow, slant, slant-inv, flames, pixels
  (flyover-border-match-icon t)

  ;; Display settings
  (flyover-hide-checker-name t)
  (flyover-show-virtual-line t)
  (flyover-virtual-line-type 'curved-dotted-arrow)
  (flyover-line-position-offset 1)

  ;; Message wrapping
  (flyover-wrap-messages t)
  (flyover-max-line-length 80)

  ;; Performance
  (flyover-debounce-interval 0.2)
  (flyover-cursor-debounce-interval 0.3)

  ;; Display mode (controls cursor-based visibility)
  (flyover-display-mode 'always)

  ;; Completion integration
  (flyover-hide-during-completion t)

  :config
  (defun prot/flyover--blend (fg bg alpha)
    "Mix FG into BG, keeping ALPHA (0.0-1.0) of FG.  Return a hex string."
    (let ((f (color-values fg))
          (b (color-values bg)))
      (apply #'format "#%02x%02x%02x"
             (cl-mapcar (lambda (fc bc)
                          (/ (round (+ (* fc alpha) (* bc (- 1 alpha)))) 256))
                        f b))))

  ;; Set explicit face backgrounds blended 12% toward the buffer background.
  ;; Flyover's own derivation (fg * lightness) only ever darkens, so it produces
  ;; near-black blocks on light themes; an explicit :background bypasses it.
  (defun prot/flyover-sync-faces (&rest _)
    "Give flyover's faces backgrounds derived from the active theme."
    (let ((bg (face-attribute 'default :background nil t)))
      (when (and bg (not (eq bg 'unspecified)) (color-defined-p bg))
        (pcase-dolist (`(,flyover-face . ,theme-face)
                       '((flyover-error   . error)
                         (flyover-warning . warning)
                         (flyover-info    . success)))
          (let ((fg (face-attribute theme-face :foreground nil t)))
            (when (and fg (not (eq fg 'unspecified)) (color-defined-p fg))
              (set-face-attribute
               flyover-face nil
               :foreground fg
               :background (prot/flyover--blend fg bg 0.12))))))
      (when (fboundp 'flyover--clear-color-cache)
        (flyover--clear-color-cache))))

  ;; Re-sync on manual theme switches.
  (add-hook 'enable-theme-functions #'prot/flyover-sync-faces)
  (prot/flyover-sync-faces))
