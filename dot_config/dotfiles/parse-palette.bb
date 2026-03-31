#!/usr/bin/env bb
;; parse-palette.bb — Extract color palette from a Prot elisp theme file
;;
;; Usage:
;;   bb parse-palette.bb <theme-file.el>           Parse a single theme file
;;   bb parse-palette.bb <theme-file.el> <name>    Parse file, extract palette for <name>
;;
;; For modus-themes, the palettes live in modus-themes.el (not the individual theme files).
;; Pass the main file with the theme name:
;;   bb parse-palette.bb modus-themes.el modus-operandi
;;
;; Outputs JSON: {"name": "ef-autumn", "variant": "dark", "colors": {"bg-main": "#0f0e06", ...}}
;; Only extracts concrete color values (hex strings), not symbolic mappings.

(require '[clojure.string :as str]
         '[cheshire.core :as json])

(defn parse-palette
  "Parse (name \"#hex\") pairs from text.
   Returns a map of {name hex-color}."
  [text]
  (->> text
       (re-seq #"\((\S+)\s+\"(#[0-9a-fA-F]{6})\"\)")
       (map (fn [[_ name color]] [(str/replace name #"^\(+" "") color]))
       (into {})))

(defn detect-variant
  "Detect whether a theme is dark or light.
   Checks the first line of the file for 'dark' or 'light',
   or infers from the theme name (modus-operandi=light, modus-vivendi=dark)."
  [source theme-name]
  (let [first-line (first (str/split-lines source))]
    (cond
      (re-find #"(?i)\bdark\b" (or first-line ""))     "dark"
      (re-find #"(?i)\blight\b" (or first-line ""))    "light"
      (str/includes? theme-name "operandi")             "light"
      (str/includes? theme-name "vivendi")              "dark"
      ;; Fallback: check if bg-main is dark (< #808080)
      :else (let [m (re-find #"bg-main\s+\"#([0-9a-fA-F]{2})" source)]
              (if (and m (vector? m))
                (if (< (Integer/parseInt (second m) 16) 0x80)
                  "dark"
                  "light")
                "dark")))))

(defn extract-theme-name
  "Derive the theme name from the filename.
   ef-autumn-theme.el → ef-autumn, doric-dark-theme.el → doric-dark"
  [filepath]
  (-> filepath
      (str/replace #".*/([^/]+)$" "$1")
      (str/replace #"-theme\.el$" "")
      (str/replace #"\.el$" "")))

(defn find-named-palette
  "Find a specific palette definition by theme name in the source.
   Tries several naming patterns used by Prot's themes:
   - defconst NAME-palette-partial (ef-themes)
   - defconst modus-themes-NAME-palette (modus-themes, NAME without 'modus-' prefix)
   - defvar NAME-palette (doric-themes)"
  [source theme-name]
  (let [;; Build pattern variations for the theme name
        ;; modus-operandi → try: modus-operandi-palette, modus-themes-operandi-palette
        short-name (str/replace theme-name #"^modus-" "")
        patterns [(str theme-name "-palette-partial")
                  (str theme-name "-palette")
                  (str "modus-themes-" short-name "-palette")]
        ;; For each pattern, try to extract the palette block
        find-block (fn [pat]
                     (let [;; Escape hyphens for regex
                           escaped (str/replace pat "-" "\\-")
                           re (re-pattern (str "(?s)(?:defconst|defvar)\\s+"
                                               escaped
                                               "\\s+(?:\\(append\\s+)?'?\\s*\\((?:\\s|;;[^\\n]*)*(\\(.+?\\))\\s*\\)"))
                           matches (re-seq re source)]
                       (when (seq matches)
                         (str/join "\n" (map second matches)))))]
    (some find-block patterns)))

(let [filepath (first *command-line-args*)
      explicit-name (second *command-line-args*)]
  (when-not filepath
    (binding [*out* *err*]
      (println "Usage: bb parse-palette.bb <file.el> [theme-name]")
      (println "")
      (println "Examples:")
      (println "  bb parse-palette.bb ef-autumn-theme.el")
      (println "  bb parse-palette.bb modus-themes.el modus-operandi"))
    (System/exit 1))

  (let [source (slurp filepath)
        name (or explicit-name (extract-theme-name filepath))
        variant (detect-variant source name)
        palette-text (or (find-named-palette source name)
                         ;; Fallback: extract all hex colors from the entire file
                         source)
        colors (parse-palette palette-text)]
    (when (empty? colors)
      (binding [*out* *err*]
        (println (str "Warning: no colors found for '" name "' in " filepath))))
    (println (json/generate-string {:name name :variant variant :colors colors} {:pretty true}))))
