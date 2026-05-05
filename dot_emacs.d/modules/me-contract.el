;;; me-contract.el --- Config contract compiler: JSON → Elisp -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; me-contract is a compiler that turns JSON configuration files into
;; plain Elisp source.  It is a DEVELOPMENT-TIME tool — it is never
;; loaded during normal Emacs startup.  The generated `.el' files are
;; standalone, readable, and have zero dependency on this package.
;;
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;; Two-phase model
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;
;; Development time (when you edit config):
;;
;;   config/*.json  →  M-x me-contract-generate  →  generated/*.el
;;
;; Emacs startup (every launch):
;;
;;   init.el  →  (require 'me-generated-defaults)
;;            →  (require 'me-generated-editing)
;;            →  (require 'me-generated-keybindings)
;;
;; The generated files are plain `setq', `keymap-global-set', etc.
;; No registries, no dispatch, no framework code.  If something
;; breaks, you read the generated file.
;;
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;; How it works
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;
;; 1. ATOM REGISTRY — `me-defatom' registers variables with schemas
;;    (type, default, doc, module).  The generator reads the
;;    corresponding config/MODULE.json, validates each value against
;;    the schema, and emits the appropriate `setq' / `setq-default'.
;;
;; 2. SCOPE REGISTRY — `me-contract-register-scope' registers
;;    keybinding scopes.  Each scope provides an EMITTER function
;;    that takes a binding plist and returns a quoted sexp.
;;    Built-in scopes (`global', `mode') emit `keymap-global-set'
;;    and `keymap-set'.  Package-specific scopes (hel, evil, meow)
;;    are registered by the modules that load those packages.
;;    The framework has zero knowledge of any specific package.
;;
;; 3. PREFIX EMITTERS — registered functions that emit code for
;;    prefix group labels (e.g., which-key descriptions).  Called
;;    for every labeled branch node in the keybinding tree.
;;
;; 4. TREE FLATTENER — the keybinding JSON supports nested prefix
;;    groups.  The flattener runs at generation time, producing flat
;;    binding plists that scope emitters consume.
;;
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;; JSON file conventions
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;
;; Variable configs (per-module, flat objects):
;;
;;   config/defaults.json:
;;   { "use-short-answers": true, "bookmark-save-flag": 1 }
;;
;; Keybinding configs (single file, mixed flat/tree array):
;;
;;   config/keybindings.json:
;;   [
;;     { "prefix": "M-g", "label": "goto", "scope": "global",
;;       "bindings": [
;;         { "key": "g", "command": "consult-goto-line" },
;;         { "key": "o", "command": "consult-outline" }
;;       ]},
;;     { "key": "C-x C-b", "command": "ibuffer", "scope": "global" }
;;   ]
;;
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;; Registering a package-specific keybinding scope
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;
;; In your modal editing module, after the package loads:
;;
;;   (me-contract-register-scope 'hel-state
;;     :required-fields '(state)
;;     :emitter (lambda (entry)
;;                `(hel-keymap-global-set
;;                  :state ',(plist-get entry :state)
;;                  ,(plist-get entry :key)
;;                  #',(plist-get entry :command))))
;;
;; The emitter returns a quoted sexp.  The generator pretty-prints
;; it into the output file.  At startup, Emacs evaluates it as
;; plain elisp — no framework involved.
;;
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;; The "data, not code" invariant
;; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
;;
;; JSON config files contain no computation.  Users cannot write
;; lambdas, defuns, or any expression requiring evaluation.
;; References to named functions are permitted — they are data
;; (symbols that resolve via lookup).  The compiler reads JSON
;; via `json-read', never `eval'.

;;; Code:

(require 'cl-lib)
(require 'json)

;; ═══════════════════════════════════════════════════════════════════
;; Atom Registry
;; ═══════════════════════════════════════════════════════════════════

(defvar me-contract--registry (make-hash-table :test 'eq)
  "Hash table of registered atoms.
Each entry maps an atom name (symbol) to a plist:
  :atom-type    - symbol (e.g., `variable')
  :module       - symbol (e.g., `defaults')
  :type         - type spec for validation
  :default      - the default value
  :doc          - description string
  :buffer-local - if non-nil, emit `setq-default'")

(defun me-contract-registered-p (name)
  "Return non-nil if NAME is a registered atom."
  (gethash name me-contract--registry))

(defun me-contract-get (name)
  "Return the registration plist for atom NAME, or nil."
  (gethash name me-contract--registry))

(defun me-contract-atoms-for-module (module)
  "Return an alist of (NAME . PLIST) for all atoms in MODULE.
Sorted alphabetically by name."
  (let (result)
    (maphash (lambda (name reg)
               (when (eq (plist-get reg :module) module)
                 (push (cons name reg) result)))
             me-contract--registry)
    (sort result (lambda (a b)
                   (string< (symbol-name (car a))
                            (symbol-name (car b)))))))

(defun me-contract--all-modules ()
  "Return a sorted list of all module symbols with registered atoms."
  (let (modules)
    (maphash (lambda (_name reg)
               (let ((mod (plist-get reg :module)))
                 (when (and mod (not (memq mod modules)))
                   (push mod modules))))
             me-contract--registry)
    (sort modules (lambda (a b)
                    (string< (symbol-name a) (symbol-name b))))))

;; ═══════════════════════════════════════════════════════════════════
;; Scope Registry
;; ═══════════════════════════════════════════════════════════════════

(defvar me-contract--scope-registry (make-hash-table :test 'eq)
  "Hash table mapping scope symbols to scope definitions.
Each entry is a plist:
  :emitter         - function taking a binding plist, returns a quoted sexp
  :required-fields - list of field symbols required for this scope")

(defun me-contract-register-scope (scope &rest props)
  "Register a keybinding scope for codegen.
SCOPE is a symbol (e.g., `global', `mode', `hel-state').
PROPS is a plist:
  :emitter         - function taking a binding plist, returning a quoted sexp
  :required-fields - list of field symbols required for this scope

The emitter is called at generation time.  Its return value is
pretty-printed into the generated elisp file.

Example — registering a Hel scope:

  (me-contract-register-scope \\='hel-state
    :required-fields \\='(state)
    :emitter (lambda (entry)
               `(hel-keymap-global-set
                 :state \\=',(plist-get entry :state)
                 ,(plist-get entry :key)
                 #\\=',(plist-get entry :command))))"
  (puthash scope
           (list :emitter (plist-get props :emitter)
                 :required-fields (plist-get props :required-fields))
           me-contract--scope-registry))

(defun me-contract-scope-registered-p (scope)
  "Return non-nil if keybinding SCOPE is registered."
  (gethash scope me-contract--scope-registry))

;; ═══════════════════════════════════════════════════════════════════
;; Prefix Emitters
;; ═══════════════════════════════════════════════════════════════════

(defvar me-contract--prefix-emitters nil
  "List of functions called for each labeled prefix node.
Each function receives (PREFIX-KEY LABEL CONTEXT) and returns
a quoted sexp (or nil to skip).  The sexp is emitted into the
generated keybindings file before the prefix group's bindings.")

(defun me-contract-register-prefix-emitter (emitter-fn)
  "Register EMITTER-FN to emit code for prefix group labels.
EMITTER-FN receives (PREFIX-KEY LABEL CONTEXT) and returns a
quoted sexp or nil.

Example — which-key integration:

  (me-contract-register-prefix-emitter
   (lambda (prefix label _ctx)
     `(when (fboundp \\='which-key-add-key-based-replacements)
        (which-key-add-key-based-replacements ,prefix ,label))))"
  (cl-pushnew emitter-fn me-contract--prefix-emitters))

;; ═══════════════════════════════════════════════════════════════════
;; Type Checking
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--check-type (value type-spec)
  "Return t if VALUE conforms to TYPE-SPEC.
TYPE-SPEC is a simplified type language:
  boolean, natnum, integer, number, string, symbol,
  function, sexp, (one-of A B C)."
  (pcase type-spec
    ('boolean (or (eq value t) (eq value nil)))
    ('natnum (and (integerp value) (>= value 0)))
    ('integer (integerp value))
    ('number (numberp value))
    ('string (stringp value))
    ('symbol (symbolp value))
    ('function (symbolp value))
    ('sexp t)
    (`(one-of . ,choices) (member value choices))
    (_ (error "me-contract: unknown type-spec: %S" type-spec))))

;; ═══════════════════════════════════════════════════════════════════
;; Registration Macro
;; ═══════════════════════════════════════════════════════════════════

(defmacro me-defatom (atom-type target &rest props)
  "Register an atom in the contract registry.

ATOM-TYPE is the kind of atom (e.g., `variable').
TARGET is the symbol being configured.
PROPS: :module, :type, :default, :doc, :buffer-local.

Example:
  (me-defatom variable use-short-answers
    :module defaults :type boolean :default t
    :doc \"Use y/n instead of yes/no\")"
  (declare (indent 2))
  `(puthash ',target
            (list :atom-type ',atom-type
                  :module ',(plist-get props :module)
                  :type ',(plist-get props :type)
                  :default ,(plist-get props :default)
                  :doc ,(plist-get props :doc)
                  :buffer-local ,(plist-get props :buffer-local))
            me-contract--registry))

;; ═══════════════════════════════════════════════════════════════════
;; JSON ↔ Elisp Conversion
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--json-to-elisp (json-val type-spec)
  "Convert a JSON value to Elisp, guided by TYPE-SPEC."
  (pcase type-spec
    ('boolean (cond ((eq json-val t) t)
                    ((eq json-val :json-false) nil)
                    ((eq json-val :json-null) nil)
                    ((eq json-val nil) nil)
                    (t json-val)))
    ('symbol (if (stringp json-val) (intern json-val) json-val))
    ('function (if (stringp json-val) (intern json-val) json-val))
    (`(one-of . ,_)
     (if (stringp json-val) (intern json-val) json-val))
    (_ json-val)))

(defun me-contract--elisp-to-json (val type-spec)
  "Convert an Elisp value to JSON-safe representation."
  (cond ((and (eq val t) (eq type-spec 'boolean)) t)
        ((and (eq val nil) (eq type-spec 'boolean)) :json-false)
        ((eq val nil) :json-null)
        ((symbolp val) (symbol-name val))
        (t val)))

(defun me-contract--intern-if-string (val)
  "Intern VAL if it's a string, return as-is otherwise."
  (if (stringp val) (intern val) val))

(defun me-contract--convert-state (raw)
  "Convert a JSON state value to a symbol or list of symbols."
  (cond
   ((null raw) nil)
   ((stringp raw) (intern raw))
   ((vectorp raw) (mapcar #'intern (append raw nil)))
   (t raw)))

;; ═══════════════════════════════════════════════════════════════════
;; Variable Emitter
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--emit-variable (target value registration)
  "Return a sexp that sets TARGET to VALUE.
Emits `setq-default' for buffer-local atoms, `setq' otherwise.
Symbols are quoted in the output so they evaluate correctly."
  (let ((quoted-val (if (and (symbolp value) (not (booleanp value)))
                        `',value
                      value)))
    (if (plist-get registration :buffer-local)
        `(setq-default ,target ,quoted-val)
      `(setq ,target ,quoted-val))))

;; ═══════════════════════════════════════════════════════════════════
;; Keybinding Conversion and Validation
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--convert-keybinding (alist)
  "Convert a JSON keybinding ALIST to a plist with Elisp types."
  (list :key     (alist-get 'key alist)
        :command (me-contract--intern-if-string (alist-get 'command alist))
        :scope   (me-contract--intern-if-string (alist-get 'scope alist))
        :keymap  (me-contract--intern-if-string (alist-get 'keymap alist))
        :state   (me-contract--convert-state (alist-get 'state alist))))

(defun me-contract--validate-keybinding (entry)
  "Validate a keybinding ENTRY plist.
Returns nil if valid, or an error message string."
  (let ((key (plist-get entry :key))
        (command (plist-get entry :command))
        (scope (plist-get entry :scope)))
    (cond
     ((not (and key (stringp key) (> (length key) 0)))
      (format "keybinding missing or empty 'key': %S" key))
     ((not (key-valid-p key))
      (format "invalid key sequence: %S" key))
     ((not (and command (symbolp command)))
      (format "keybinding 'command' must be a non-nil symbol, got: %S" command))
     ((not scope)
      "keybinding missing 'scope'")
     ((not (me-contract-scope-registered-p scope))
      (format "scope '%s' is not registered — is the package module loaded?" scope))
     (t
      (let* ((scope-def (gethash scope me-contract--scope-registry))
             (required (plist-get scope-def :required-fields)))
        (cl-loop for field in required
                 when (null (plist-get entry (intern (format ":%s" field))))
                 return (format "scope '%s' requires field '%s'" scope field)))))))

;; ═══════════════════════════════════════════════════════════════════
;; Keybinding Tree Flattener
;; ═══════════════════════════════════════════════════════════════════
;;
;; Recursively walks a mixed tree/flat JSON array.  Branches have
;; `prefix' + `bindings'; leaves have `key' + `command'.  A node
;; can be both.  Children inherit scope, state, keymap from parents.
;;
;; Returns two values via the accumulator pattern:
;;   - sections: list of (:header STRING :forms (SEXP ...))
;;   - flat-entries: binding alists for top-level leaves

(defun me-contract--flatten-keybindings (data)
  "Flatten a mixed tree/flat JSON structure.
Returns a list of flat binding alists."
  (nreverse (me-contract--flatten-recurse data "" nil nil)))

(defun me-contract--flatten-recurse (entries prefix-key context results)
  "Recursively flatten keybinding ENTRIES into RESULTS."
  (seq-doseq (entry-alist (if (vectorp entries) entries (list entries)))
    (let* ((node-prefix (alist-get 'prefix entry-alist))
           (node-key    (alist-get 'key entry-alist))
           (label       (alist-get 'label entry-alist))
           (command     (alist-get 'command entry-alist))
           (bindings    (alist-get 'bindings entry-alist))
           (local-key   (or node-prefix node-key))
           (full-key    (if (and prefix-key (> (length prefix-key) 0)
                                local-key (> (length local-key) 0))
                            (concat prefix-key " " local-key)
                          (or local-key prefix-key "")))
           (new-context  (me-contract--merge-context context entry-alist)))
      ;; Mark prefix nodes for section headers in output.
      (when (and label bindings)
        (push (list (cons 'me--prefix-label label)
                    (cons 'me--prefix-key full-key))
              results))
      ;; Emit leaf.
      (when command
        (push (me-contract--build-leaf-alist full-key command new-context)
              results))
      ;; Recurse into children.
      (when bindings
        (setq results
              (me-contract--flatten-recurse
               bindings full-key new-context results)))))
  results)

(defun me-contract--merge-context (parent-ctx entry-alist)
  "Merge inheritable fields from ENTRY-ALIST into PARENT-CTX."
  (let ((ctx (copy-alist parent-ctx)))
    (dolist (field '(scope state keymap))
      (let ((val (alist-get field entry-alist)))
        (when val (setf (alist-get field ctx) val))))
    ctx))

(defun me-contract--build-leaf-alist (full-key command context)
  "Build a flat binding alist from FULL-KEY, COMMAND, and CONTEXT."
  (let ((alist (list (cons 'key full-key)
                     (cons 'command command))))
    (dolist (pair context)
      (when (cdr pair)
        (push (cons (car pair) (cdr pair)) alist)))
    alist))

;; ═══════════════════════════════════════════════════════════════════
;; JSON Reader
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--read-json (file)
  "Read and return parsed JSON from FILE."
  (let ((json-object-type 'alist)
        (json-key-type 'symbol)
        (json-false :json-false)
        (json-null :json-null))
    (json-read-file file)))

;; ═══════════════════════════════════════════════════════════════════
;; Code Generator — Variables
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--generate-module (module gen-dir)
  "Generate me-generated-MODULE.el from config/MODULE.json.
Validates each entry and emits the appropriate setq/setq-default."
  (let* ((json-file (expand-file-name (format "config/%s.json" module)
                                       user-emacs-directory))
         (out-name (format "me-generated-%s" module))
         (out-file (expand-file-name (concat out-name ".el") gen-dir))
         (feature (intern out-name))
         forms)
    (if (not (file-exists-p json-file))
        (message "me-contract: %s not found — skipping" json-file)
      (let ((data (me-contract--read-json json-file)))
        (dolist (entry data)
          (let* ((target (car entry))
                 (json-val (cdr entry))
                 (reg (me-contract-get target)))
            (unless reg
              (error "me-contract: unknown atom '%s' in %s" target json-file))
            (let* ((type-spec (plist-get reg :type))
                   (value (me-contract--json-to-elisp json-val type-spec)))
              (unless (me-contract--check-type value type-spec)
                (error "me-contract: type error for '%s' — expected %S, got %S"
                       target type-spec value))
              (push (list :form (me-contract--emit-variable target value reg)
                          :doc (plist-get reg :doc))
                    forms)))))
      (setq forms (nreverse forms))
      (me-contract--write-generated-file
       out-file feature (format "config/%s.json" module) forms)
      (message "me-contract: generated %s (%d atoms)" out-name (length forms)))))

;; ═══════════════════════════════════════════════════════════════════
;; Code Generator — Keybindings
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--generate-keybindings (gen-dir)
  "Generate me-generated-keybindings.el from config/keybindings.json."
  (let* ((json-file (expand-file-name "config/keybindings.json"
                                       user-emacs-directory))
         (out-file (expand-file-name "me-generated-keybindings.el" gen-dir))
         forms)
    (if (not (file-exists-p json-file))
        (message "me-contract: config/keybindings.json not found — skipping")
      (let* ((data (me-contract--read-json json-file))
             (flat-entries (me-contract--flatten-keybindings data)))
        (dolist (raw-entry flat-entries)
          (if (alist-get 'me--prefix-label raw-entry)
              (let* ((label (alist-get 'me--prefix-label raw-entry))
                     (prefix-key (alist-get 'me--prefix-key raw-entry)))
                (push (list :section-header
                            (format "── %s · %s" prefix-key label))
                      forms)
                (dolist (emitter me-contract--prefix-emitters)
                  (let ((sexp (funcall emitter prefix-key label nil)))
                    (when sexp
                      (push (list :form sexp) forms)))))
            (let* ((entry (me-contract--convert-keybinding raw-entry))
                   (err (me-contract--validate-keybinding entry)))
              (when err
                (error "me-contract: keybinding error — %s" err))
              (let* ((scope (plist-get entry :scope))
                     (scope-def (gethash scope me-contract--scope-registry))
                     (emitter (plist-get scope-def :emitter))
                     (sexp (funcall emitter entry)))
                (push (list :form sexp) forms))))))
      (setq forms (nreverse forms))
      (me-contract--write-keybinding-file out-file forms)
      (message "me-contract: generated me-generated-keybindings (%d entries)"
               (cl-count-if (lambda (f) (plist-get f :form)) forms)))))

;; ═══════════════════════════════════════════════════════════════════
;; File Writers
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract--write-generated-file (file feature source forms)
  "Write variable FORMS to FILE as a generated elisp module.
FEATURE is the `provide' symbol.  SOURCE is the config file path.
FORMS is a list of plists with :form and optionally :doc."
  (with-temp-file file
    (insert (format ";;; %s --- Generated from %s -*- lexical-binding: t; no-byte-compile: t -*-\n"
                    (file-name-nondirectory file) source))
    (insert ";; Generated by me-contract-generate — do not edit by hand.\n")
    (insert (format ";; Generated: %s\n\n;;; Code:\n\n"
                    (format-time-string "%Y-%m-%dT%H:%M:%S")))
    (dolist (f forms)
      (let ((sexp (plist-get f :form))
            (doc (plist-get f :doc)))
        (let ((line (string-trim-right (pp-to-string sexp))))
          (insert line)
          (when doc
            (let ((col (length (car (last (split-string line "\n"))))))
              (when (< col 48)
                (insert (make-string (- 48 col) ?\s)))
              (insert " ; " doc)))
          (insert "\n"))))
    (insert (format "\n(provide '%s)\n" feature))
    (insert (format ";;; %s ends here\n" (file-name-nondirectory file)))))

(defun me-contract--write-keybinding-file (file forms)
  "Write keybinding FORMS to FILE.
FORMS is a list of plists, each either :form (a sexp) or
:section-header (a string for a comment divider)."
  (with-temp-file file
    (insert ";;; me-generated-keybindings.el --- Generated from config/keybindings.json -*- lexical-binding: t; no-byte-compile: t -*-\n")
    (insert ";; Generated by me-contract-generate — do not edit by hand.\n")
    (insert (format ";; Generated: %s\n\n;;; Code:\n"
                    (format-time-string "%Y-%m-%dT%H:%M:%S")))
    (dolist (f forms)
      (cond
       ((plist-get f :section-header)
        (insert (format "\n;; %s %s\n\n"
                        (plist-get f :section-header)
                        (make-string
                         (max 0 (- 60 (length (plist-get f :section-header))))
                         ?─))))
       ((plist-get f :form)
        (insert (string-trim-right (pp-to-string (plist-get f :form))))
        (insert "\n"))))
    (insert "\n(provide 'me-generated-keybindings)\n")
    (insert ";;; me-generated-keybindings.el ends here\n")))

;; ═══════════════════════════════════════════════════════════════════
;; Custom Generator Registry
;; ═══════════════════════════════════════════════════════════════════
;;
;; For config files that don't fit the variable atom pattern (like
;; appearance, which emits composite fontaine/theme code), modules
;; can register custom generators.  Each generator is a function
;; that takes GEN-DIR and handles its own JSON reading and file writing.

(defvar me-contract--custom-generators nil
  "List of (NAME . FUNCTION) pairs for custom generators.
Each function takes GEN-DIR as its sole argument.")

(defun me-contract-register-generator (name generator-fn)
  "Register a custom generator.
NAME is a symbol for logging.  GENERATOR-FN takes GEN-DIR and
produces a generated .el file from its own config JSON source."
  (push (cons name generator-fn) me-contract--custom-generators))

;; ═══════════════════════════════════════════════════════════════════
;; Top-Level Generate Command
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract-generate ()
  "Generate elisp files from JSON config.
Reads all registered modules, keybindings, and custom generators.
Validates and writes generated/*.el files.

Run this after editing any config/*.json file:
  M-x me-contract-generate

Or from the shell:
  emacs --batch -l modules/me-contract.el \\
    -l modules/me-defaults-atoms.el \\
    -l modules/me-scopes.el \\
    -f me-contract-generate"
  (interactive)
  (let ((gen-dir (expand-file-name "generated" user-emacs-directory)))
    (make-directory gen-dir t)
    ;; Variable modules.
    (dolist (module (me-contract--all-modules))
      (me-contract--generate-module module gen-dir))
    ;; Keybindings.
    (when (file-exists-p (expand-file-name "config/keybindings.json"
                                            user-emacs-directory))
      (me-contract--generate-keybindings gen-dir))
    ;; Custom generators.
    (dolist (entry me-contract--custom-generators)
      (funcall (cdr entry) gen-dir))
    (message "me-contract: generation complete")))

;; ═══════════════════════════════════════════════════════════════════
;; Scaffold Generator
;; ═══════════════════════════════════════════════════════════════════

(defun me-contract-scaffold-module (module)
  "Write a JSON config file for MODULE with all registered defaults.
File is written to config/MODULE.json.  Existing files are NOT
overwritten."
  (let* ((atoms (me-contract-atoms-for-module module))
         (file (expand-file-name
                (format "config/%s.json" module)
                user-emacs-directory))
         entries)
    (if (file-exists-p file)
        (message "me-contract: %s already exists — not overwriting" file)
      (dolist (atom atoms)
        (let* ((name (car atom))
               (reg (cdr atom))
               (type-spec (plist-get reg :type))
               (default (plist-get reg :default))
               (json-val (me-contract--elisp-to-json default type-spec)))
          (push (cons name json-val) entries)))
      (setq entries (nreverse entries))
      (with-temp-file file
        (insert (json-encode entries))
        (json-pretty-print-buffer))
      (message "me-contract: scaffolded %d atoms to %s"
               (length entries) file))))

(defun me-contract-scaffold-all ()
  "Scaffold config files for all modules that have registered atoms."
  (dolist (mod (me-contract--all-modules))
    (me-contract-scaffold-module mod)))

(provide 'me-contract)
;;; me-contract.el ends here
