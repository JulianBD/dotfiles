;; Loaded first; every exported function becomes a typed command (:name).
;; Functions annotated with ;;@doc show their docs in the command picker.
(require "helix/editor.scm")
(require "helix/misc.scm")
(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "cogs/recentf.scm")
(require "cogs/git-status-picker.scm")
(require "cogs/file-tree.scm")
(require "cogs/helix-ext.scm")
(require "cogs/scheme-indent.scm")
(require "focus.scm")
(require "steel-pty/term.scm")
(require "helix-file-watcher/file-watcher.scm")

(provide shell
         git-add
         open-helix-scm
         open-init-scm
         recentf-open-files
         create-gs-picker
         create-file-tree
         eval-buffer
         scheme-indent
         focus
         unfocus
         open-term
         new-term
         switch-term
         kill-active-terminal
         hide-terminal
         spawn-watcher)

(define (current-path)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])
    (editor-document->path focus-doc-id)))

;;@doc
;; Run a shell command; % expands to the current file.
(define (shell . args)
  (helix.run-shell-command
   (string-join
    (map (lambda (x) (if (equal? x "%") (current-path) x)) args)
    " ")))

;;@doc
;; git add the current file.
(define (git-add)
  (shell "git" "add" "%"))

;;@doc
;; Open ~/.config/helix/helix.scm.
(define (open-helix-scm)
  (helix.open (helix.static.get-helix-scm-path)))

;;@doc
;; Open ~/.config/helix/init.scm.
(define (open-init-scm)
  (helix.open (helix.static.get-init-scm-path)))
