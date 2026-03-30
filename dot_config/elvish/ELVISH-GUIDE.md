# Elvish as a Primary Shell: A Practical Guide

Elvish is to the terminal what Elisp is to Emacs. Where bash gives you string
manipulation and hope, elvish gives you structured data, lexical closures,
namespaces, exception handling, and a programmable editor. It's a real
programming language that doubles as your shell — not a shell with scripting
bolted on.

This guide walks through daily-driving elvish and building your own modules,
using the packages already installed in your config as concrete examples.

---

## Part 1: The Language

### Values, not strings

The single most important shift from bash/fish: elvish pipelines carry typed
values. Numbers are numbers. Lists are lists. Maps are maps. There is no
implicit string splitting, no word expansion, no `$IFS`.

```elvish
# These are different types
put 42              # number
put "hello"         # string
put [a b c]         # list
put [&x=1 &y=2]    # map
put $true           # boolean
put {|| echo hi}    # lambda (function value)
```

The `put` command writes values to the value pipeline. `echo` writes bytes
to stdout. Both work in pipes, but values are what make elvish powerful:

```elvish
# Parse JSON into a map, extract a field — no jq needed
curl -s https://api.github.com/repos/elves/elvish | from-json | {|repo|
  echo $repo[full_name]": "$repo[stargazers_count]" stars"
}

# Process structured data through a pipeline
put [&name=alice &role=eng] [&name=bob &role=sre] | keep-if {|p|
  eq $p[role] sre
} | each {|p|
  echo $p[name]
}
# Output: bob
```

### Variables and scoping

Variables are declared with `var`, assigned with `set`. Elvish uses lexical
scoping — a variable is visible in the block where it's declared and any
nested blocks.

```elvish
var name = "world"
{
  # Inner block sees outer variable
  echo $name             # "world"
  var local = "inner"    # Only visible in this block
}
# echo $local            # Would error: variable not found
```

Namespaces use colons. Environment variables live in `E:`:

```elvish
set-env EDITOR nvim       # Set env var
echo $E:HOME              # Read env var
echo $paths               # The PATH as a list (not a colon-separated string)
```

### Functions are values

Every function is a lambda. `fn name {|args| body}` is syntactic sugar for
`var name~ = {|args| body}`. The `~` suffix marks a callable.

```elvish
fn greet {|who|
  echo "hello "$who
}

# These are equivalent:
greet world
$greet~ world

# Functions are first-class values — pass them around
fn apply-twice {|f x|
  $f ($f $x)
}
apply-twice {|n| * $n 2} 3   # 12
```

Named options use `&`:

```elvish
fn deploy {|service &env=staging &dry-run=$false|
  if $dry-run {
    echo "would deploy "$service" to "$env
    return
  }
  echo "deploying "$service" to "$env
  kubectl -n $env rollout restart deployment/$service
}

deploy api-gateway                      # staging, for real
deploy api-gateway &env=production      # production, for real
deploy api-gateway &dry-run             # staging, dry run
```

### Closures and state

Closures capture variables from their enclosing scope. This is how you build
stateful abstractions without global variables:

```elvish
fn make-retry {|max-attempts|
  var attempts = 0
  put {|f|
    set attempts = 0
    while (< $attempts $max-attempts) {
      set attempts = (+ $attempts 1)
      try {
        $f
        return
      } catch e {
        echo "attempt "$attempts" failed: "$e[reason]
        if (>= $attempts $max-attempts) {
          fail "giving up after "$max-attempts" attempts"
        }
        sleep 1
      }
    }
  }
}

var retry = (make-retry 3)
$retry { curl -sf https://flaky-service.internal/health }
```

### Error handling

External commands that exit non-zero throw exceptions. No silent failures,
no checking `$?`:

```elvish
# This throws if the file doesn't exist
cat /nonexistent

# Catch it
try {
  cat /nonexistent
} catch e {
  echo "failed: "$e[reason]
}

# For commands where failure is expected, suppress with ?()
var exists = ?(test -f /maybe/here)
```

### Data structures in depth

**Lists** are immutable. Operations return new lists:

```elvish
var items = [alpha bravo charlie]
echo $items[0]                    # alpha
echo $items[1:]                   # [bravo charlie]
echo (count $items)               # 3

# Functional operations
each {|x| str:to-upper $x} $items           # ALPHA BRAVO CHARLIE
keep-if {|x| str:has-prefix $x "c"} $items  # [charlie]
var more = (conj $items delta)               # [alpha bravo charlie delta]
```

**Maps** are also immutable:

```elvish
var server = [&host=db.local &port=(num 5432) &ssl=$true]
echo $server[host]                # db.local
keys $server | to-lines           # host, port, ssl
has-key $server ssl               # $true

var updated = (assoc $server port (num 5433))
echo $updated[port]               # 5433
echo $server[port]                # 5432 (original unchanged)
```

**Nested structures** work naturally:

```elvish
var config = [
  &database=[&host=db.local &port=(num 5432)]
  &cache=[&host=redis.local &ttl=(num 300)]
  &features=[&dark-mode=$true &beta=$false]
]
echo $config[database][host]      # db.local
echo $config[features][dark-mode] # $true
```

---

## Part 2: The Module System

This is where the Elisp analogy is strongest. Like Emacs's `require` and
`provide`, elvish has `use` and file-based modules with automatic namespacing.

### How modules work

Any `.elv` file in the library path is a module. The library paths are:

1. `~/.config/elvish/lib/` (your personal modules)
2. `~/.local/share/elvish/lib/` (epm-installed packages)

Create `~/.config/elvish/lib/mytools.elv` and it becomes `use mytools`.
Everything defined with `fn` or `var` at the top level of the file is
exported as `mytools:functionname` or `$mytools:varname`.

Directories create nested namespaces. Your theme system already uses this:

```
lib/dotfiles/
  theme.elv       → use dotfiles/theme    → theme:apply, theme:list
  palette.elv     → use dotfiles/palette  → palette:sync, palette:get
  generate.elv    → use dotfiles/generate → generate:ghostty, generate:all
```

### Building a module: bullet journal

Let's build something you'll actually use — a plaintext bullet journal
that lives at the command line. Entries have types (note, event, task,
mood) and tasks have states (todo, doing, done). One file per day,
plain text, greppable.

The finished module gives you:

```elvish
bj:note "switched to elvish as primary shell"
bj:event "standup at 10am"
bj:task "fix parse-palette regex"
bj:task "write elvish guide" &state=doing
bj:done "fix parse-palette regex"       # marks it done
bj:mood "good — flow state all morning"
bj:today                                 # show today's entries
bj:log                                   # show recent days
bj:grep "elvish"                         # search across all entries
```

Create `~/.config/elvish/lib/bj.elv`:

```elvish
# bj.elv — Bullet journal at the command line
#
# Plaintext entries with types: note, event, task, mood.
# Tasks have states: todo, doing, done.
# One markdown file per day in ~/journal/.
#
# Usage:
#   use bj
#   bj:note "some thought"
#   bj:event "meeting at 2pm"
#   bj:task "fix the bug"
#   bj:task "refactor theme system" &state=doing
#   bj:done "fix the bug"
#   bj:mood "focused, energetic"
#   bj:today
#   bj:log &days=7
#   bj:grep "pattern"

use str
use path
use re

# --- Configuration ---

var dir = ~/journal

# Bullet characters for each entry type
var bullets = [
  &note="•"
  &event="○"
  &todo="·"
  &doing="→"
  &done="×"
  &mood="~"
]

# --- Private helpers ---

fn -today-str {
  date +%Y-%m-%d | str:trim-space (slurp)
}

fn -file-for {|date-str|
  put $dir/$date-str.md
}

fn -ensure-dir {
  mkdir -p $dir
}

fn -timestamp {
  date +%H:%M | str:trim-space (slurp)
}

fn -append {|date-str line|
  -ensure-dir
  var f = (-file-for $date-str)

  # Create file with date header if new
  if (not (path:is-regular $f)) {
    echo "# "$date-str > $f
    echo "" >> $f
  }

  echo $line >> $f
}

fn -format-entry {|bullet text|
  var ts = (-timestamp)
  put $bullets[$bullet]" "$text"  ("$ts")"
}

# --- Public API: writing entries ---

fn note {|@text|
  var body = (str:join " " $text)
  var line = (-format-entry note $body)
  -append (-today-str) $line
  echo $line
}

fn event {|@text|
  var body = (str:join " " $text)
  var line = (-format-entry event $body)
  -append (-today-str) $line
  echo $line
}

fn task {|@text &state=todo|
  var body = (str:join " " $text)
  if (not (has-key $bullets $state)) {
    fail "unknown state: "$state" (use todo, doing, or done)"
  }
  var line = (-format-entry $state $body)
  -append (-today-str) $line
  echo $line
}

fn mood {|@text|
  var body = (str:join " " $text)
  var line = (-format-entry mood $body)
  -append (-today-str) $line
  echo $line
}

# --- Public API: updating tasks ---

fn done {|@text|
  # Mark a task as done. Appends a new "done" entry — doesn't modify
  # the original. The journal is append-only.
  var body = (str:join " " $text)
  var line = (-format-entry done $body)
  -append (-today-str) $line
  echo $line
}

fn doing {|@text|
  # Mark a task as in-progress.
  var body = (str:join " " $text)
  var line = (-format-entry doing $body)
  -append (-today-str) $line
  echo $line
}

# --- Public API: reading entries ---

fn today {
  var f = (-file-for (-today-str))
  if (path:is-regular $f) {
    cat $f
  } else {
    echo "No entries for today."
  }
}

fn show {|date-str|
  var f = (-file-for $date-str)
  if (path:is-regular $f) {
    cat $f
  } else {
    echo "No entries for "$date-str"."
  }
}

fn log {|&days=7|
  # Show the last N days that have entries
  -ensure-dir
  var files = [(e:ls -r $dir | keep-if {|f| str:has-suffix $f .md })]
  var shown = 0
  for f $files {
    if (>= $shown $days) {
      break
    }
    echo ""
    cat $dir/$f
    set shown = (+ $shown 1)
  }
  if (== $shown 0) {
    echo "No journal entries yet."
  }
}

fn grep {|pattern|
  # Search across all journal entries
  -ensure-dir
  try {
    e:rg --color=always $pattern $dir
  } catch e {
    echo "No matches for '"$pattern"'."
  }
}

# --- Public API: summary ---

fn open-tasks {
  # Show all tasks that aren't done yet.
  # Scans today's file for todo/doing bullets not followed by a done bullet
  # for the same text.
  var f = (-file-for (-today-str))
  if (not (path:is-regular $f)) {
    echo "No entries for today."
    return
  }

  var done-set = [&]
  var pending = []

  from-lines < $f | each {|line|
    # Extract entries with done bullet
    if (str:has-prefix $line $bullets[done]) {
      var text = (re:replace '^.\s+(.+?)\s+\(\d+:\d+\)$' '${1}' $line)
      set done-set = (assoc $done-set $text $true)
    }
    # Collect todo and doing entries
    if (or (str:has-prefix $line $bullets[todo]) ^
           (str:has-prefix $line $bullets[doing])) {
      set pending = (conj $pending $line)
    }
  }

  # Show pending tasks not in done-set
  each {|line|
    var text = (re:replace '^.\s+(.+?)\s+\(\d+:\d+\)$' '${1}' $line)
    if (not (has-key $done-set $text)) {
      echo $line
    }
  } $pending
}
```

A day's journal file (`~/journal/2026-03-28.md`) looks like:

```markdown
# 2026-03-28

• switched to elvish as primary shell  (09:15)
○ standup at 10am  (09:30)
· fix parse-palette regex  (09:32)
→ write elvish guide  (10:00)
× fix parse-palette regex  (11:45)
~ good — flow state all morning  (12:00)
```

### Wiring up completions and an alias

Add this to your `interactive.elv` to get tab completion for task states
and a short alias:

```elvish
use bj

# Tab-complete the &state option for bj:task
set edit:completion:arg-completer[bj:task] = {|@args|
  put todo doing done
}

# Short alias: j note "...", j task "...", j today, etc.
edit:add-var j~ {|subcmd @rest|
  var cmds = [&note=$bj:note~ &event=$bj:event~ &task=$bj:task~
              &mood=$bj:mood~ &done=$bj:done~ &doing=$bj:doing~
              &today=$bj:today~ &log=$bj:log~ &show=$bj:show~
              &grep=$bj:grep~ &open=$bj:open-tasks~]
  if (has-key $cmds $subcmd) {
    $cmds[$subcmd] $@rest
  } else {
    echo "unknown: "$subcmd". try: "(str:join ", " [(keys $cmds | order)])
  }
}
```

Now you can use either style:

```elvish
bj:note "remembered something"    # Module syntax
j note "remembered something"     # Short alias
j today                           # See today's entries
j open                            # See open tasks
```

### What this module demonstrates

Every section of the module maps to an elvish concept:

1. **Module variables** — `$dir`, `$bullets` are exported config that users
   could override before calling functions
2. **Maps as configuration** — `$bullets` maps entry types to their symbols,
   used throughout without hardcoding
3. **Private functions** — the `-` prefix convention (`-today-str`,
   `-append`, `-format-entry`) keeps internals out of the public API, just
   like Elisp's double-dash `my-module--internal` convention
4. **Rest parameters** — `{|@text|}` collects all arguments into a list,
   so `bj:note these are all words` works without quoting
5. **Named options** — `{|@text &state=todo|}` gives `task` a default state
   while allowing `&state=doing` override
6. **Immutable data patterns** — `(assoc $done-set $text $true)` builds up
   a set by creating new maps, never mutating
7. **Value pipelines** — `from-lines < $f | each {|line| ...}` streams file
   lines through a transformation
8. **Regex** — `re:replace` extracts task text from formatted lines
9. **Error handling** — `try/catch` around `rg` in `grep` handles the case
   where nothing matches (exit code 1)
10. **Styled output** — entries use unicode bullets for visual scanning
11. **Completions** — `edit:completion:arg-completer` hooks into tab for
    task states
12. **Function dispatch** — the `j` alias uses a map of command names to
    function values, demonstrating first-class functions as a dispatch table

---

## Part 3: The Interactive Editor

The `edit:` namespace is elvish's equivalent of Emacs's keymap and hook
system. Everything about the interactive experience is programmable.

### Modes and keybindings

Elvish's editor has modes like vi/Emacs: insert, completion, navigation,
history. Each mode has its own binding table:

```elvish
# Insert mode (normal typing)
set edit:insert:binding[Ctrl-A] = { edit:move-dot-sol }
set edit:insert:binding[Ctrl-E] = { edit:move-dot-eol }

# Completion mode (when completing)
set edit:completion:binding[Tab] = { edit:completion:accept }

# Bind to a function value
set edit:insert:binding[Alt-g] = $projects:go~
```

### Custom completions

For any command, you can define how arguments complete:

```elvish
# Complete `ssh` with known hosts
set edit:completion:arg-completer[ssh] = {|@args|
  cat ~/.ssh/known_hosts | each {|line|
    str:split " " $line | take 1
  }
}

# Complete `git checkout` with branch names
set edit:completion:arg-completer[git] = {|@args|
  if (eq $args[1] checkout) {
    git branch --format='%(refname:short)' | from-lines
  }
}
```

Carapace (already in your config) provides completions for 400+ commands
automatically — but you can override specific ones when you want more
control.

### Hooks

```elvish
# before-readline: runs before each prompt (like Emacs pre-command-hook)
set edit:before-readline = [$@edit:before-readline {
  # Refresh git status, update env vars, etc.
}]

# after-readline: runs after you press Enter (post-command-hook)
set edit:after-readline = [$@edit:after-readline {|cmd|
  # Log commands, track time, etc.
}]

# after-command: runs after command finishes (with duration, error info)
set edit:after-command = [$@edit:after-command {|m|
  if (> $m[duration] 5.0) {
    echo "that took "(printf "%.1f" $m[duration])"s"
  }
}]
```

The `terminal-title` and `long-running-notifications` packages in your config
work by hooking into exactly these points.

### Prompts

```elvish
# Left prompt
set edit:prompt = {
  styled (tilde-abbr $pwd) blue
  put " "
  styled "λ " green
}

# Right prompt
set edit:rprompt = {
  try {
    var branch = (git branch --show-current 2>/dev/null | slurp | str:trim-space)
    if (not-eq $branch "") {
      styled $branch bright-black
    }
  } catch e { }
}
```

You're using Starship instead (which takes over `edit:prompt`), but knowing
how the native system works is useful when you want to extend or debug it.

---

## Part 4: Your Installed Packages

### alias (zzamboni/elvish-modules)

Cleaner than raw `edit:add-var`. Aliases persist across sessions:

```elvish
alias:new cat bat --style=plain --paging=never  # Define
alias:new ls eza                                 # Define
alias:list                                       # Show all
alias:undef cat                                  # Remove
alias:new tf terraform &save                     # Define and persist to disk
```

Under the hood, `alias:new` calls `edit:add-var` and optionally writes
the alias to `~/.config/elvish/aliases/name.elv`.

### bang-bang (zzamboni/elvish-modules)

Brings bash-style history expansion to elvish:

- `!!` — insert the entire last command
- `!$` — insert the last argument of the last command
- `!0` — insert the command name (first word)
- `!1`, `!2`, ... — insert the Nth argument
- `!*` — insert all arguments (without the command)

Type `!` and you'll see an interactive selector showing the last command
broken into words.

### dir (zzamboni/elvish-modules)

Directory history with navigation:

- **Alt-b** — go back one directory (or move cursor left if on a line)
- **Alt-f** — go forward (or move cursor right)
- **Alt-i** — interactive directory history picker
- `dir:cd -` — go to previous directory (like `cd -` in bash)
- `dir:history` — show the full directory stack

### smart-matcher (xiaq/edit.elv)

Upgrades tab completion with progressive matching. When you type `foo<Tab>`:

1. First tries prefix match: commands starting with `foo`
2. Then smart-case prefix: `Foo`, `FOO` also match
3. Then substring: commands containing `foo` anywhere
4. Then smart-case substring
5. Then subsequence: `f...o...o` scattered through the name
6. Then smart-case subsequence

You don't interact with it directly — it just makes tab completion smarter.

### long-running-notifications (zzamboni/elvish-modules)

Automatically sends a macOS notification when a command takes longer than
10 seconds. Commands in the `never-notify` list (vi, less, etc.) are excluded.

Customize the threshold:

```elvish
set long-running-notifications:threshold = 30  # 30 seconds instead of 10
```

### rivendell (crinklywrappr)

A functional programming library. The most useful modules:

```elvish
use github.com/crinklywrappr/rivendell/fun
use github.com/crinklywrappr/rivendell/lazy

# fun: higher-order functions
fun:reduce {|acc x| + $acc $x} 0 [1 2 3 4 5]  # 15

# lazy: infinite sequences and transducers
lazy:take 10 (lazy:iterate {|n| + $n 1} 0)     # [0 1 2 3 4 5 6 7 8 9]
```

### carapace

Universal completions for 400+ commands. Loads lazily — the first time you
tab-complete a supported command, carapace generates the completion spec.
No configuration needed. If you want to override a specific command's
completions, just set `edit:completion:arg-completer[command]` yourself —
your definition takes precedence.

---

## Part 5: Patterns for Daily Use

### JSON as a first-class citizen

```elvish
# Read config
var config = (from-json < config.json)
echo $config[database][host]

# Transform and write
put $config | to-json > config.json.bak

# API calls
var repos = (curl -s "https://api.github.com/users/protesilaos/repos?per_page=5" | from-json)
each {|r| echo $r[name]": "$r[stargazers_count]" stars"} $repos
```

### Parallel execution

```elvish
# peach is parallel each — runs the lambda concurrently
var hosts = [web1 web2 web3 db1 db2]
peach {|h| ssh $h "uptime" } $hosts
```

### Converting bash idioms

| Bash | Elvish |
|------|--------|
| `$(command)` | `(command)` |
| `"${var:-default}"` | `(or $var default)` |
| `export FOO=bar` | `set-env FOO bar` |
| `$@` | `$@args` (rest parameter) |
| `${arr[@]}` | `$@list` (splice into args) |
| `[[ -f file ]]` | `path:is-regular file` |
| `[[ -d dir ]]` | `path:is-dir dir` |
| `source file.sh` | `eval (slurp < file.elv)` |
| `cmd \| while read line` | `cmd \| each {|line| ...}` |
| `if cmd; then` | `try { cmd } catch { }` or `if ?(cmd) { }` |
| `cmd1 && cmd2` | `cmd1; cmd2` (exceptions halt) |
| `cmd1 \|\| cmd2` | `try { cmd1 } catch e { cmd2 }` |
| `for i in $(seq 10)` | `for i [(range 10)]` or `range 10 \| each {|i| ...}` |

### Writing scripts

Scripts are `.elv` files. They don't load rc.elv. They have access to
all language features but not the `edit:` namespace (that's interactive only).

```elvish
#!/usr/bin/env elvish
# cleanup.elv — Remove old build artifacts

use path
use str

var max-age = 7  # days
var dry-run = $false

# Parse flags
for arg $args {
  if (eq $arg --dry-run) {
    set dry-run = $true
  }
}

e:find ./build -name "*.tar.gz" -mtime +$max-age | each {|f|
  if $dry-run {
    echo "would remove: "$f
  } else {
    rm $f
    echo "removed: "$f
  }
}
```

---

## Part 6: Your Config Architecture

```
~/.config/elvish/
├── rc.elv                  ← Entry point (chezmoi template)
│   ├── PATH & environment
│   ├── mise activation (--shims)
│   ├── epm package installs
│   ├── Starship prompt
│   ├── Zoxide navigation
│   ├── eval interactive.elv
│   └── use dotfiles
│
├── interactive.elv         ← Editor config (eval'd for edit: access)
│   ├── readline-binding
│   ├── zzamboni modules (alias, bang-bang, dir, terminal-title, notifications)
│   ├── xiaq smart-matcher
│   ├── carapace completions
│   ├── Aliases (cat→bat, ls→eza, find→fd, vim→nvim, j→just)
│   ├── Dir nav keybindings (Alt-b/f/i)
│   └── Ctrl-R fzf history
│
├── lib/
│   ├── dotfiles.elv        ← Module wrapper
│   └── dotfiles/
│       ├── theme.elv       ← theme:apply, theme:pick
│       ├── palette.elv     ← palette DB from Prot's repos
│       └── generate.elv    ← ghostty, sketchybar, borders, wallpaper
│
└── ELVISH-GUIDE.md         ← This file
```

The split between `rc.elv` and `interactive.elv` exists because elvish
compiles rc.elv as a single unit. The `edit:` namespace is available at
runtime in interactive sessions but not at compile time, so anything
touching `edit:` must live in a file loaded via `eval` (which creates a
separate compilation unit). This is the same reason `starship init` and
`zoxide init` use `eval` — their output references `edit:` hooks.

---

## Quick Reference

```elvish
# Your theme system
dotfiles:theme:pick                    # Interactive theme picker
dotfiles:theme:apply modus-operandi    # Apply directly
dotfiles:theme:list                    # All available themes
dotfiles:theme:sync                    # Rebuild palette DB from upstream

# Aliases
alias:list                             # Show all aliases
alias:new name command args...         # Define a new alias

# Directory navigation
dir:history                            # Show directory stack

# REPL inspection
put $edit:insert:binding               # All insert-mode keybindings
keys $edit:completion:arg-completer    # All custom completers

# Package management
epm:list                               # Installed packages
epm:upgrade github.com/user/repo       # Update a package
```
