#!/usr/bin/env janet

# tangle.janet -- extract fenced code blocks from literate markdown
#
# Fence format (inspired by org-mode :tangle header arg):
#
#   ```zig :tangle src/main.zig
#   const std = @import("std");
#   ```
#
# Directives appear after the language in the info string as :key value pairs.
# Only :tangle is acted on. Blocks sharing a :tangle target concatenate in
# document order. Blocks without :tangle are skipped (documentation only).
#
# Usage:
#   janet tangle.janet <file.md> [base-dir]

# --- PEG ----------------------------------------------------------------
# Matches fenced code blocks: ``` info-line \n body \n ```
# Captures (info-line, body) pairs grouped per block.
# Closing ``` must be on its own line (preceded by \n).

(def fence-peg
  (peg/compile
    ~{:main (any (+ :fence 1))
      :fence (group (* "```"
                       (capture (to "\n"))
                       "\n"
                       (capture (to "\n```"))
                       "\n```"
                       (+ "\n" -1)))}))

# --- info line parser ----------------------------------------------------

(defn parse-info
  "Parse fence info string into {:lang str|nil :props {key value ...}}"
  [info]
  (def result @{:lang nil :props @{}})
  (def toks (string/split " " info))
  (var i 0)
  # first token is language if it doesn't start with :
  (when (and (> (length toks) 0)
             (> (length (toks 0)) 0)
             (not (string/has-prefix? ":" (toks 0))))
    (put result :lang (toks 0))
    (set i 1))
  # remaining tokens are :key value pairs
  (while (< i (length toks))
    (def t (in toks i))
    (if (string/has-prefix? ":" t)
      (let [k (string/slice t 1)]
        (++ i)
        (if (< i (length toks))
          (do (put (result :props) k (in toks i))
              (++ i))
          (do (put (result :props) k true)
              (++ i))))
      (++ i)))
  result)

# --- fs helpers -----------------------------------------------------------

(defn mkdirp
  "Create parent directories for a file path."
  [path]
  (def parts (filter |(> (length $) 0) (string/split "/" path)))
  (when (> (length parts) 1)
    (var acc (if (string/has-prefix? "/" path) "" "."))
    (for i 0 (- (length parts) 1)
      (set acc (if (= acc ".")
                 (in parts i)
                 (string acc "/" (in parts i))))
      (os/mkdir acc))))

# --- tangle ---------------------------------------------------------------

(defn tangle [md-path &opt base-dir]
  (default base-dir ".")
  (def content (slurp md-path))
  (def matches (peg/match fence-peg content))
  (unless matches
    (print "No fenced code blocks found.")
    (os/exit 0))

  (def files @{})
  (def order @[])
  (var n 0)

  (each block matches
    (def [info body] block)
    (def parsed (parse-info info))
    (when-let [target (get-in parsed [:props "tangle"])]
      (def full (if (string/has-prefix? "/" target)
                  target
                  (string base-dir "/" target)))
      (unless (in files full)
        (put files full @[])
        (array/push order full))
      (array/push (in files full) body)
      (++ n)))

  (when (= n 0)
    (print "No :tangle blocks found.")
    (os/exit 0))

  # write files in first-seen order
  (each path order
    (def bodies (in files path))
    (mkdirp path)
    (spit path (string/join bodies "\n"))
    (printf "  %s (%d blocks)" path (length bodies)))
  (printf "Tangled %d blocks into %d files." n (length order)))

# --- main -----------------------------------------------------------------

(def args (dyn :args))
(when (< (length args) 2)
  (eprint "Usage: janet tangle.janet <file.md> [base-dir]")
  (os/exit 1))
(tangle (in args 1)
        (if (>= (length args) 3) (in args 2) "."))
