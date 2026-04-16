use str
use path
use dotfiles/generate/common

fn write {|palette &variant=light|
  var dir = ~/.config/glamour
  mkdir -p $dir
  var out = $dir/style.json

  var fg   = $palette[fg-main]
  var dim  = (common:c $palette fg-dim (common:c $palette fg-neutral $fg))
  var red     = (common:c $palette red (common:c $palette fg-red $fg))
  var green   = (common:c $palette green (common:c $palette fg-green $fg))
  var yellow  = (common:c $palette yellow (common:c $palette fg-yellow $fg))
  var blue    = (common:c $palette blue (common:c $palette fg-blue $fg))
  var magenta = (common:c $palette magenta (common:c $palette fg-magenta $fg))
  var cyan    = (common:c $palette cyan (common:c $palette fg-cyan $fg))

  var blue-w    = (common:c $palette blue-warmer $blue)
  var cyan-w    = (common:c $palette cyan-warmer $cyan)
  var green-c   = (common:c $palette green-cooler $green)
  var magenta-c = (common:c $palette magenta-cooler $magenta)
  var yellow-w  = (common:c $palette yellow-warmer $yellow)

  print '{
  "document": {
    "block_prefix": "\n",
    "block_suffix": "\n",
    "color": "'$fg'",
    "margin": 2
  },
  "block_quote": {
    "indent": 1,
    "indent_token": "│ ",
    "color": "'$dim'"
  },
  "paragraph": {},
  "list": {
    "color": "'$fg'",
    "level_indent": 2
  },
  "heading": {
    "block_suffix": "\n",
    "bold": true,
    "color": "'$blue'"
  },
  "h1": {
    "prefix": "# ",
    "bold": true
  },
  "h2": {
    "prefix": "## "
  },
  "h3": {
    "prefix": "### ",
    "color": "'$cyan'"
  },
  "h4": {
    "prefix": "#### "
  },
  "h5": {
    "prefix": "##### "
  },
  "h6": {
    "prefix": "###### ",
    "bold": false
  },
  "text": {},
  "strikethrough": {
    "crossed_out": true
  },
  "emph": {
    "italic": true
  },
  "strong": {
    "bold": true
  },
  "hr": {
    "color": "'$dim'",
    "format": "\n--------\n"
  },
  "item": {
    "block_prefix": "• "
  },
  "enumeration": {
    "block_prefix": ". ",
    "color": "'$blue'"
  },
  "task": {
    "ticked": "[✓] ",
    "unticked": "[ ] "
  },
  "link": {
    "color": "'$cyan'",
    "underline": true
  },
  "link_text": {
    "color": "'$cyan-w'",
    "bold": true
  },
  "image": {
    "color": "'$magenta'",
    "underline": true
  },
  "image_text": {
    "color": "'$dim'",
    "format": "Image: {{.text}} →"
  },
  "code": {
    "prefix": " ",
    "suffix": " ",
    "color": "'$green-c'"
  },
  "code_block": {
    "color": "'$fg'",
    "margin": 2,
    "chroma": {
      "text":                { "color": "'$fg'" },
      "error":               { "color": "'$red'" },
      "comment":             { "color": "'$dim'", "italic": true },
      "comment_preproc":     { "color": "'$cyan'" },
      "keyword":             { "color": "'$magenta'", "bold": true },
      "keyword_reserved":    { "color": "'$magenta-c'", "bold": true },
      "keyword_namespace":   { "color": "'$red'" },
      "keyword_type":        { "color": "'$cyan-w'" },
      "operator":            { "color": "'$red'" },
      "punctuation":         { "color": "'$dim'" },
      "name":                {},
      "name_builtin":        { "color": "'$blue-w'" },
      "name_tag":            { "color": "'$magenta'" },
      "name_attribute":      { "color": "'$cyan'" },
      "name_class":          { "color": "'$blue'", "underline": true, "bold": true },
      "name_constant":       { "color": "'$magenta-c'" },
      "name_decorator":      { "color": "'$yellow'" },
      "name_exception":      {},
      "name_function":       { "color": "'$green'" },
      "name_other":          {},
      "literal":             {},
      "literal_number":      { "color": "'$cyan'" },
      "literal_date":        {},
      "literal_string":      { "color": "'$yellow-w'" },
      "literal_string_escape": { "color": "'$cyan'" },
      "generic_deleted":     { "color": "'$red'" },
      "generic_emph":        { "italic": true },
      "generic_inserted":    { "color": "'$green'" },
      "generic_strong":      { "bold": true },
      "generic_subheading":  { "color": "'$dim'" }
    }
  },
  "table": {},
  "definition_list": {},
  "definition_term": {},
  "definition_description": {
    "block_prefix": "\n→ "
  },
  "html_block": {},
  "html_span": {}
}
' > $out

  echo 'Glamour: wrote '$out
}
