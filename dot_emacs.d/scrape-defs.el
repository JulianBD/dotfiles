;;; scrape-defs.el --- Extract API surface from installed packages to org -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Walks installed packages and extracts every def* form into a single
;; org-mode document: scraped-api.org.  Grouped by package, then by
;; form type.  Includes all derivable metadata: arglists, interactive
;; specs, defcustom types, face specs, keymap bindings, etc.
;;
;; Filtering is controlled by config/scrape-rules.json (see below).
;;
;; Usage:
;;   emacs --batch --init-directory . -l early-init.el -l init.el -l scrape-defs.el

;;; Code:

(require 'package)
(require 'cl-lib)
(require 'json)

;; ═══════════════════════════════════════════════════════════════════
;; Scrape Rules
;; ═══════════════════════════════════════════════════════════════════

(defvar me-scrape-rules nil
  "Parsed scrape rules from config/scrape-rules.json.")

(defvar me-scrape-default-rules
  '(:include ("^{pkg}-" "^{pkg-base}-")
    :exclude ("--"))
  "Built-in default rules.  {pkg} and {pkg-base} are expanded per package.")

(defun me--load-scrape-rules ()
  "Load scrape rules from config/scrape-rules.json if it exists."
  (let ((file (expand-file-name "config/scrape-rules.json"
                                 user-emacs-directory)))
    (if (file-exists-p file)
        (let ((json-object-type 'alist)
              (json-key-type 'string)
              (json-false :json-false)
              (json-null :json-null))
          (setq me-scrape-rules (json-read-file file)))
      (setq me-scrape-rules nil))))

(defun me--expand-pattern (pattern pkg-name pkg-base)
  "Expand {pkg} and {pkg-base} placeholders in PATTERN."
  (let ((result pattern))
    (setq result (replace-regexp-in-string (regexp-quote "{pkg-base}") pkg-base result t t))
    (setq result (replace-regexp-in-string (regexp-quote "{pkg}") pkg-name result t t))
    result))

(defun me--pkg-base-name (pkg-name)
  "Strip common suffixes (-mode, -el, .el) from PKG-NAME."
  (let ((name pkg-name))
    (dolist (suffix '("-mode" "-el" ".el"))
      (when (string-suffix-p suffix name)
        (setq name (substring name 0 (- (length name) (length suffix))))))
    name))

(defun me--rules-for-package (pkg-name)
  "Return (INCLUDE-REGEXPS . EXCLUDE-REGEXPS) for PKG-NAME."
  (let* ((pkg-base (me--pkg-base-name pkg-name))
         (override (when me-scrape-rules
                     (cdr (assoc pkg-name
                                 (cdr (assoc "overrides" me-scrape-rules))))))
         (file-defaults (when me-scrape-rules
                          (cdr (assoc "defaults" me-scrape-rules))))
         (raw-include (cond
                       ((cdr (assoc "include" override)))
                       ((cdr (assoc "include" file-defaults)))
                       ((plist-get me-scrape-default-rules :include))))
         (raw-exclude (cond
                       ((cdr (assoc "exclude" override)))
                       ((cdr (assoc "exclude" file-defaults)))
                       ((plist-get me-scrape-default-rules :exclude))))
         (include-list (if (vectorp raw-include) (append raw-include nil) raw-include))
         (exclude-list (if (vectorp raw-exclude) (append raw-exclude nil) raw-exclude)))
    (cons (mapcar (lambda (p) (me--expand-pattern p pkg-name pkg-base)) include-list)
          (mapcar (lambda (p) (me--expand-pattern p pkg-name pkg-base)) exclude-list))))

(defun me--symbol-matches-rules-p (sym-name rules)
  "Return non-nil if SYM-NAME passes RULES (INCLUDE . EXCLUDE)."
  (and (cl-some (lambda (rx) (string-match-p rx sym-name)) (car rules))
       (not (cl-some (lambda (rx) (string-match-p rx sym-name)) (cdr rules)))))

;; ═══════════════════════════════════════════════════════════════════
;; Form Metadata Extraction
;; ═══════════════════════════════════════════════════════════════════

(defun me--extract-plist-val (form key)
  "Extract value following KEY in the plist tail of FORM."
  (let ((tail (memq key (cddr form))))
    (when tail (cadr tail))))

(defun me--extract-docstring (form)
  "Extract docstring from a def* FORM if present."
  (let ((pos (pcase (car form)
               ((or 'defcustom 'defvar 'defconst 'defvar-local) 4)
               ((or 'defun 'defmacro 'defsubst) 4)
               ('defface 4)
               ('define-minor-mode 3)
               ('defvar-keymap 3)
               ('define-derived-mode 5)
               ('define-globalized-minor-mode 4)
               (_ nil))))
    (when (and pos (> (length form) (1- pos)))
      (let ((candidate (nth (1- pos) form)))
        (when (stringp candidate) candidate)))))

(defun me--extract-interactive (form)
  "Extract the (interactive ...) spec from a defun FORM body, or nil."
  (let ((body (cdddr form)))  ; skip name, arglist, possible docstring
    (when (stringp (car body)) (setq body (cdr body)))  ; skip docstring
    (when (and (consp (car body)) (eq (caar body) 'declare))
      (setq body (cdr body)))  ; skip declare
    (when (and (consp (car body)) (eq (caar body) 'interactive))
      (car body))))

(defun me--scrape-form (form file)
  "Extract all derivable metadata from a def* FORM in FILE."
  (let* ((type (car form))
         (name (cadr form))
         (fname (file-name-nondirectory file))
         (doc (me--extract-docstring form))
         (entry (list :type type :name name :file fname)))
    ;; Add docstring.
    (when doc (setq entry (plist-put entry :doc doc)))
    ;; Type-specific metadata.
    (pcase type
      ('defcustom
       (setq entry (plist-put entry :default (nth 2 form)))
       (let ((ct (me--extract-plist-val form :type)))
         (when ct (setq entry (plist-put entry :custom-type ct))))
       (let ((group (me--extract-plist-val form :group)))
         (when group (setq entry (plist-put entry :group group))))
       (when (me--extract-plist-val form :set)
         (setq entry (plist-put entry :has-setter t))))

      ((or 'defun 'defmacro 'defsubst)
       (let ((arglist (nth 2 form)))
         (setq entry (plist-put entry :arglist arglist)))
       (let ((interactive (me--extract-interactive form)))
         (when interactive
           (setq entry (plist-put entry :interactive t))
           (when (and (consp interactive) (cadr interactive))
             (setq entry (plist-put entry :interactive-spec (cadr interactive)))))))

      ('defface
       (setq entry (plist-put entry :spec (nth 2 form)))
       (let ((group (me--extract-plist-val form :group)))
         (when group (setq entry (plist-put entry :group group)))))

      ('defvar-keymap
       (let (bindings)
         (let ((tail (cddr form)))
           (while tail
             (if (keywordp (car tail))
                 (let ((kw (car tail)) (val (cadr tail)))
                   (when (eq kw :parent)
                     (setq entry (plist-put entry :parent val)))
                   (setq tail (cddr tail)))
               (when (and (stringp (car tail)) (cdr tail))
                 (push (cons (car tail) (cadr tail)) bindings))
               (setq tail (cddr tail)))))
         (when bindings
           (setq entry (plist-put entry :bindings (nreverse bindings))))))

      ('define-minor-mode
       (let ((body (cddr form)))
         (when (stringp (car body)) (setq body (cdr body))) ; skip doc
         ;; Scan keyword args.
         (while (keywordp (car body))
           (let ((kw (car body)) (val (cadr body)))
             (pcase kw
               (:global (setq entry (plist-put entry :global val)))
               (:lighter (setq entry (plist-put entry :lighter val)))
               (:keymap (when (symbolp val)
                          (setq entry (plist-put entry :keymap val)))))
             (setq body (cddr body))))))

      ('define-derived-mode
       (setq entry (plist-put entry :parent-mode (nth 2 form))))

      ('define-globalized-minor-mode
       (setq entry (plist-put entry :turn-on (nth 2 form))))

      ((or 'defvar 'defvar-local 'defconst)
       (setq entry (plist-put entry :default (nth 2 form)))
       (when (eq type 'defvar-local)
         (setq entry (plist-put entry :buffer-local t)))
       (when (eq type 'defconst)
         (setq entry (plist-put entry :constant t)))))
    entry))

;; ═══════════════════════════════════════════════════════════════════
;; File and Package Scrapers
;; ═══════════════════════════════════════════════════════════════════

(defun me--scrape-file (file rules)
  "Read def* forms from FILE, filtered by RULES."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let (forms)
      (condition-case nil
          (while t
            (let* ((form (read (current-buffer)))
                   (name (and (consp form)
                              (symbolp (car form))
                              (string-prefix-p "def" (symbol-name (car form)))
                              (symbolp (cadr form))
                              (symbol-name (cadr form))))
                   (entry (and name
                               (me--symbol-matches-rules-p name rules)
                               (me--scrape-form form file))))
              (when entry (push entry forms))))
        (end-of-file nil))
      (nreverse forms))))

(defun me--scrape-package (pkg-desc)
  "Extract def* forms from package PKG-DESC."
  (let* ((dir (package-desc-dir pkg-desc))
         (pkg-name (symbol-name (package-desc-name pkg-desc)))
         (rules (me--rules-for-package pkg-name))
         (els (directory-files dir t "\\.el\\'" t)))
    (mapcan (lambda (f) (me--scrape-file f rules))
            (seq-remove (lambda (f) (string-match-p "-autoloads\\|-pkg" f)) els))))

;; ═══════════════════════════════════════════════════════════════════
;; Org Output
;; ═══════════════════════════════════════════════════════════════════

(defun me--org-escape (str)
  "Escape STR for safe org-mode output."
  (when str
    (replace-regexp-in-string "\\*" "\\\\*" str)))

(defun me--format-value (val)
  "Format an Elisp value as a short string for display."
  (let ((print-length 10) (print-level 3))
    (prin1-to-string val)))

(defun me--group-by-type (forms)
  "Group FORMS into an alist of (TYPE . FORMS-LIST)."
  (let (groups)
    (dolist (form forms)
      (let* ((type (plist-get form :type))
             (cell (assq type groups)))
        (if cell
            (push form (cdr cell))
          (push (list type form) groups))))
    ;; Reverse each group to preserve order, then sort groups.
    (mapcar (lambda (g) (cons (car g) (nreverse (cdr g))))
            (nreverse groups))))

(defun me--type-heading (type)
  "Return a human-readable heading for form TYPE."
  (pcase type
    ('defcustom "Variables (defcustom)")
    ('defvar "Variables (defvar)")
    ('defvar-local "Buffer-local Variables (defvar-local)")
    ('defconst "Constants (defconst)")
    ('defface "Faces (defface)")
    ('defun "Functions (defun)")
    ('defmacro "Macros (defmacro)")
    ('defsubst "Inline Functions (defsubst)")
    ('defvar-keymap "Keymaps (defvar-keymap)")
    ('define-minor-mode "Minor Modes")
    ('define-globalized-minor-mode "Globalized Minor Modes")
    ('define-derived-mode "Major Modes")
    ('defgroup "Customize Groups")
    ('defalias "Aliases")
    (_ (format "%s" type))))

(defun me--type-sort-key (type)
  "Return a sort priority for TYPE (lower = earlier)."
  (pcase type
    ('defcustom 1)
    ('define-minor-mode 2)
    ('define-globalized-minor-mode 3)
    ('define-derived-mode 4)
    ('defface 5)
    ('defvar-keymap 6)
    ('defun 7)
    ('defmacro 8)
    ('defsubst 9)
    ('defvar 10)
    ('defvar-local 11)
    ('defconst 12)
    ('defgroup 13)
    (_ 99)))

(defun me--emit-defcustom (form)
  "Emit org content for a defcustom FORM."
  (insert (format "** %s\n" (plist-get form :name)))
  (when (plist-get form :doc)
    (insert (me--org-escape (plist-get form :doc)) "\n"))
  (insert (format "- Default: =%s=\n" (me--format-value (plist-get form :default))))
  (when (plist-get form :custom-type)
    (insert (format "- Type: =%s=\n" (me--format-value (plist-get form :custom-type)))))
  (when (plist-get form :group)
    (insert (format "- Group: %s\n" (plist-get form :group))))
  (when (plist-get form :has-setter)
    (insert "- *Has custom setter* — use ~customize-set-variable~, not ~setq~\n"))
  (insert "\n"))

(defun me--emit-defun (form)
  "Emit org content for a defun/defmacro/defsubst FORM."
  (let ((arglist (plist-get form :arglist))
        (interactive (plist-get form :interactive)))
    (insert (format "** %s" (plist-get form :name)))
    (when arglist
      (insert (format " (%s)" (mapconcat #'symbol-name
                                          (if (listp arglist) arglist (list arglist))
                                          " "))))
    (insert "\n")
    (when (plist-get form :doc)
      (insert (me--org-escape (plist-get form :doc)) "\n"))
    (when interactive
      (insert "- *Interactive* — can bind to a key or call with ~M-x~\n"))
    (insert "\n")))

(defun me--emit-defface (form)
  "Emit org content for a defface FORM."
  (insert (format "** %s\n" (plist-get form :name)))
  (when (plist-get form :doc)
    (insert (me--org-escape (plist-get form :doc)) "\n"))
  (when (plist-get form :spec)
    (insert (format "- Spec: =%s=\n" (me--format-value (plist-get form :spec)))))
  (insert "\n"))

(defun me--emit-keymap (form)
  "Emit org content for a defvar-keymap FORM."
  (insert (format "** %s\n" (plist-get form :name)))
  (when (plist-get form :doc)
    (insert (me--org-escape (plist-get form :doc)) "\n"))
  (when (plist-get form :parent)
    (insert (format "- Parent: %s\n" (plist-get form :parent))))
  (let ((bindings (plist-get form :bindings)))
    (when bindings
      (insert "| Key | Command |\n|-----+---------|\n")
      (dolist (b bindings)
        (let* ((key (car b))
               (cmd (cdr b))
               ;; #'foo reads as (function foo) — unwrap it.
               (cmd-name (if (and (consp cmd) (eq (car cmd) 'function))
                             (cadr cmd)
                           cmd)))
          (insert (format "| =%s= | ~%s~ |\n" key cmd-name))))
      (insert "\n")))
  (insert "\n"))

(defun me--emit-minor-mode (form)
  "Emit org content for a define-minor-mode FORM."
  (insert (format "** %s" (plist-get form :name)))
  (when (plist-get form :global) (insert " (global)"))
  (insert "\n")
  (when (plist-get form :doc)
    (insert (me--org-escape (plist-get form :doc)) "\n"))
  (when (plist-get form :lighter)
    (insert (format "- Lighter: =%s=\n" (plist-get form :lighter))))
  (when (plist-get form :keymap)
    (insert (format "- Keymap: ~%s~\n" (plist-get form :keymap))))
  (insert "\n"))

(defun me--emit-variable (form)
  "Emit org content for a defvar/defvar-local/defconst FORM."
  (insert (format "** %s\n" (plist-get form :name)))
  (when (plist-get form :doc)
    (insert (me--org-escape (plist-get form :doc)) "\n"))
  (when (plist-get form :default)
    (insert (format "- Default: =%s=\n" (me--format-value (plist-get form :default)))))
  (when (plist-get form :buffer-local)
    (insert "- Buffer-local\n"))
  (when (plist-get form :constant)
    (insert "- *Constant* — not intended to be changed\n"))
  (insert "\n"))

(defun me--emit-generic (form)
  "Emit org content for any other FORM."
  (insert (format "** %s\n" (plist-get form :name)))
  (when (plist-get form :doc)
    (insert (me--org-escape (plist-get form :doc)) "\n"))
  (insert "\n"))

(defun me--emit-form (form)
  "Dispatch to the right emitter for FORM."
  (pcase (plist-get form :type)
    ('defcustom (me--emit-defcustom form))
    ((or 'defun 'defmacro 'defsubst) (me--emit-defun form))
    ('defface (me--emit-defface form))
    ('defvar-keymap (me--emit-keymap form))
    ((or 'define-minor-mode 'define-globalized-minor-mode)
     (me--emit-minor-mode form))
    ((or 'defvar 'defvar-local 'defconst) (me--emit-variable form))
    ('define-derived-mode
     (insert (format "** %s\n" (plist-get form :name)))
     (when (plist-get form :doc)
       (insert (me--org-escape (plist-get form :doc)) "\n"))
     (when (plist-get form :parent-mode)
       (insert (format "- Parent: ~%s~\n" (plist-get form :parent-mode))))
     (insert "\n"))
    (_ (me--emit-generic form))))

;; ═══════════════════════════════════════════════════════════════════
;; Documentation Scraper
;; ═══════════════════════════════════════════════════════════════════

(defvar me--doc-ignore-patterns
  '("ISSUE_TEMPLATE" "PULL_REQUEST" "LICENSE" "COPYING"
    "readme-template" "NEWS")
  "Filename substrings to skip when collecting documentation files.")

(defun me--find-package-docs (pkg-desc)
  "Find documentation files (org, md, README) in PKG-DESC's directory.
Returns a list of absolute paths, filtered for relevance."
  (let* ((dir (package-desc-dir pkg-desc))
         (all-docs (and dir (file-directory-p dir)
                        (directory-files-recursively
                         dir "\\.\\(org\\|md\\)$\\|README")))
         (filtered (seq-remove
                    (lambda (f)
                      (or (string-match-p "-autoloads\\|-pkg\\|\\.elc" f)
                          (cl-some (lambda (pat)
                                     (string-match-p pat f))
                                   me--doc-ignore-patterns)))
                    all-docs)))
    ;; Sort: READMEs first, then by path.
    (sort filtered
          (lambda (a b)
            (let ((a-readme (string-match-p "README" a))
                  (b-readme (string-match-p "README" b)))
              (cond ((and a-readme (not b-readme)) t)
                    ((and b-readme (not a-readme)) nil)
                    (t (string< a b))))))))

(defun me--bump-org-headings (text depth)
  "Shift all org headings in TEXT deeper by DEPTH levels."
  (with-temp-buffer
    (insert text)
    (goto-char (point-min))
    (let ((prefix (make-string depth ?*)))
      (while (re-search-forward "^\\(\\*+\\) " nil t)
        (replace-match (concat prefix (match-string 1) " "))))
    (buffer-string)))

(defun me--md-file-to-org (file)
  "Convert a markdown FILE to org-mode syntax via pandoc.
Returns the org text as a string.  Falls back to raw insert
if pandoc is not available."
  (if (executable-find "pandoc")
      (with-temp-buffer
        (call-process "pandoc" nil t nil
                      "-f" "markdown" "-t" "org"
                      "--shift-heading-level-by=3"
                      file)
        (buffer-string))
    ;; No pandoc — insert raw markdown.
    (with-temp-buffer
      (insert-file-contents file)
      (buffer-string))))

(defun me--emit-package-docs (pkg-desc)
  "Emit a * Documentation section for PKG-DESC's docs."
  (let ((docs (me--find-package-docs pkg-desc)))
    (when docs
      (insert "* Documentation\n\n")
      (dolist (doc-file docs)
        (let* ((dir (package-desc-dir pkg-desc))
               (rel (file-relative-name doc-file dir))
               (is-md (string-match-p "\\.md$" doc-file)))
          (insert (format "** %s\n\n" rel))
          (if is-md
              (insert (me--md-file-to-org doc-file))
            ;; Org files: bump headings to nest under **.
            (let ((content (with-temp-buffer
                             (insert-file-contents doc-file)
                             (buffer-string))))
              (insert (me--bump-org-headings content 2))))
          (insert "\n\n"))))))

;; ═══════════════════════════════════════════════════════════════════
;; Per-Package File Writer
;; ═══════════════════════════════════════════════════════════════════

(defun me--write-package-org (pkg-name desc forms out-dir)
  "Write a single org file for PKG-NAME to OUT-DIR.
DESC is the package-desc, FORMS is the scraped def* list."
  (let* ((outfile (expand-file-name
                   (format "%s.org" pkg-name) out-dir))
         (groups (me--group-by-type forms))
         (groups (sort groups (lambda (a b)
                                (< (me--type-sort-key (car a))
                                   (me--type-sort-key (car b)))))))
    (with-temp-file outfile
      (insert (format "#+TITLE: %s — API Surface\n" pkg-name))
      (insert "#+STARTUP: overview\n")
      (insert (format "#+DATE: %s\n\n" (format-time-string "%Y-%m-%d %H:%M")))

      ;; Documentation first — the user reads the README before the API.
      (me--emit-package-docs desc)

      ;; API surface sections.
      (dolist (group groups)
        (let ((type (car group))
              (type-forms (cdr group)))
          (insert (format "* %s (%d)\n\n"
                          (me--type-heading type) (length type-forms)))
          (dolist (form type-forms)
            (me--emit-form form)))))
    (message "  %-20s %3d forms → %s" pkg-name (length forms)
             (file-name-nondirectory outfile))))

;; ═══════════════════════════════════════════════════════════════════
;; Main
;; ═══════════════════════════════════════════════════════════════════

(me--load-scrape-rules)

(let* ((out-dir (expand-file-name "scraped/" user-emacs-directory))
       (total 0)
       (pkg-count 0))
  (make-directory out-dir t)

  (dolist (entry package-alist)
    (let* ((name (car entry))
           (desc (cadr entry))
           (defs (me--scrape-package desc))
           (has-docs (me--find-package-docs desc)))
      (when (or defs has-docs)
        (me--write-package-org name desc defs out-dir)
        (cl-incf total (length defs))
        (cl-incf pkg-count))))

  (message "\nWrote %d package files to %s (%d total forms)"
           pkg-count out-dir total))
