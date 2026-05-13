---
name: xonsh
description: Write and debug xonsh shell configuration, scripts, xontribs, aliases, completers, and event hooks. Use when the user is working with .xsh files, .xonshrc, xontrib code, or asks about xonsh syntax, subprocess operators, or environment setup. Also trigger on mentions of xonsh, xontrib, or .xsh files.
argument-hint: [what to do]
---

## Xonsh language model

Xonsh is a Python-superset shell. The parser uses context to decide between Python mode and subprocess mode: if a line is syntactically valid Python, it runs as Python; otherwise xonsh tries it as a subprocess command.

**Name shadowing warning**: assigning `test = True` shadows `/usr/bin/test`. If a name exists in the Python namespace, it's Python; otherwise it's a command. Use `del varname` or full paths to recover.

### Subprocess capture operators

| Operator | Returns | Stdout | Stderr | Raises on error |
|----------|---------|--------|--------|-----------------|
| `$()` | `str` (stripped) | captured | not captured | No |
| `!()` | `CommandPipeline` | captured | captured | No |
| `$[]` | `None` | to terminal | to terminal | No |
| `![]` | `CommandPipeline` | to terminal | to terminal | Yes |

```python
name = $(whoami)                    # capture stdout as string
result = !(ls -la /tmp)             # full result object
result.returncode                   # int
result.out                          # stdout string
result.err                          # stderr string
bool(result)                        # True if returncode == 0
$[ls -la]                           # stream to terminal, no capture
```

### Python-to-subprocess bridging with `@()`

```python
files = ['a.txt', 'b.txt']
ls -la @(files)                     # expands list to multiple args
name = "myfile"
touch @(f"/tmp/{name}.txt")         # f-string expression
```

### Pipes, redirection, globbing

```python
# Pipes chain subprocesses like bash
ls -la | grep ".py" | sort

# Redirection
echo hello > /tmp/out.txt           # stdout
cmd 2> /tmp/err.txt                 # stderr (also e> or err>)
cmd all> /tmp/both.txt              # both (also a> or &>)

# Globbing — standard and backtick forms
ls *.py                             # standard glob
ls **/*.py                          # recursive
ls g`**/*.py`                       # explicit glob syntax
ls `/tmp/.*\.py`                    # regex glob
```

## Environment variables

`$NAME` accesses env vars. `${...}` is the env dict itself. Env vars can hold any Python type, not just strings.

```python
$EDITOR = 'nvim'                    # set
$PATH.insert(0, '$HOME/.local/bin') # PATH is a list (EnvPath)
$PATH.append('/opt/bin')
del $MY_VAR                         # delete
'MY_VAR' in ${...}                  # check existence
${...}.get('MY_VAR', 'default')     # safe get

# Temporary scoping
with ${...}.swap(PGPASSWORD='secret'):
    psql -c 'select 1'
```

**Python vars vs env vars**: `x = 42` is a Python variable (not visible to subprocesses). `$X = "42"` is an env var (visible to subprocesses). Use `@(x)` to splice Python vars into subprocess commands.

### Key xonsh settings

```python
$XONSH_SHOW_TRACEBACK = True        # show Python tracebacks
$RAISE_SUBPROC_ERROR = True         # raise on subprocess failure (scripts)
$AUTO_CD = True                     # cd by typing dir name
$XONSH_AUTOPAIR = True              # auto-close brackets
$XONSH_HISTORY_BACKEND = 'sqlite'   # or 'json'
$COMPLETIONS_CONFIRM = True         # confirm ambiguous completions
$UPDATE_OS_ENVIRON = True           # sync os.environ (for Python libs)
$VI_MODE = True                     # vi keybindings
$XONSH_COLOR_STYLE = 'monokai'     # color theme
```

## Configuration files

### Load order

1. `/etc/xonsh/xonshrc` (system-wide)
2. `/etc/xonsh/rc.d/*.xsh` or `*.py` (sorted)
3. `~/.config/xonsh/rc.xsh` (XDG user config, interactive + non-interactive)
4. `~/.config/xonsh/rc.d/*.xsh` or `*.py` (sorted drop-in)
5. `~/.xonshrc` (interactive only)

RC files can be `.xsh` (xonsh syntax) or `.py` (pure Python). In pure Python, use `from xonsh.built_ins import XSH` to access `XSH.env`, `XSH.aliases`, etc.

### Modular config via rc.d/

```python
# ~/.config/xonsh/rc.xsh — or source from .xonshrc:
import os, glob
for rc in sorted(glob.glob(os.path.expanduser('~/.config/xonsh/rc.d/*.xsh'))):
    source @(rc)
```

## Aliases

Three forms, all via the `aliases` dict:

```python
# String alias (parsed by xonsh)
aliases['g'] = 'git'

# List alias (faster, no parsing)
aliases['ll'] = ['ls', '-la', '--color=auto']

# Callable alias (most powerful)
@aliases.register('mkcd')
def _mkcd(args):
    """Create dir and cd into it."""
    mkdir -p @(args[0])
    cd @(args[0])
```

### Callable alias parameters

Declare only what you need: `args`, `stdin`, `stdout`, `stderr`, `spec`, `stack`, `alias_name`, `env`.

```python
@aliases.register('upper')
def _upper(args, stdin=None, stdout=None):
    """Uppercase piped input."""
    if stdin:
        for line in stdin:
            stdout.write(line.upper())
    return 0

# Usage: echo hello | upper
```

Return values: `int` (return code), `str` (captured by `$()`), or `(stdout, stderr, returncode)` tuple.

### Threading

Callable aliases run in a separate thread by default (for pipeline support). Mark interactive tools as unthreadable:

```python
@aliases.register
@aliases.unthreadable
def _vi(args):
    vim @(args)
```

### Command decorators

```python
data = $(@json curl https://api.example.com/data.json)
lines = $(@lines cat file)
```

## Completers

Priority-ordered chain. Each completer returns a set of completions or `None` to defer.

### Modern API (contextual_completer)

```python
from xonsh.completers.tools import contextual_completer, RichCompletion
from xonsh.parsers.completion_context import CompletionContext

@contextual_completer
def _my_completer(context: CompletionContext):
    if context.command is None:
        return None
    if context.command.args and context.command.args[0].value == 'myapp':
        prefix = context.command.prefix
        return {
            RichCompletion(c, description=desc)
            for c, desc in [('sub1', 'First'), ('sub2', 'Second')]
            if c.startswith(prefix)
        }
    return None
```

### Classic API

```python
def _my_completer(prefix, line, begidx, endidx, ctx):
    if not line.startswith('mycommand '):
        return None
    return {'--verbose', '--quiet', '--help'}

# Register: completer add mycommand _my_completer start
```

## Events

```python
@events.on_precommand
def _(cmd, **kw):
    """Before every command."""
    pass

@events.on_postcommand
def _(cmd, rtn, out, ts, **kw):
    """After every command. ts = [start_time, end_time]."""
    pass

@events.on_chdir
def _(olddir, newdir, **kw):
    """On directory change."""
    pass

@events.on_transform_command
def _(cmd, **kw) -> str:
    """Rewrite command before execution. Must return string."""
    return cmd

@events.on_pre_prompt
def _(**kw):
    """Before prompt display."""
    pass

# Env var hooks
@events.on_envvar_new
def _(name, value, **kw): pass

@events.on_envvar_change
def _(name, oldvalue, newvalue, **kw): pass
```

Always include `**kw` in handler signatures for forward compatibility.

## Macros

Capture arguments as raw source text rather than evaluating them.

```python
# Function macros — annotations control capture mode
def log_and_run(code : str, compiled : compile):
    print(f"Running: {code}")
    exec(compiled)

log_and_run!(x = 42; print(x))

# Context manager macros — capture entire with-block body
with! trace:
    x = 1
    y = x + 2
```

Annotation types: `str` (source text), `ast.AST` (parsed), `compile` (code object), `exec`/`eval` (run immediately).

## Prompt

```python
$PROMPT = '{env_name}{BOLD_GREEN}{user}@{hostname}{RESET}:{BOLD_BLUE}{cwd}{RESET}{curr_branch: [{}]} $ '
$RIGHT_PROMPT = '{localtime}'
$BOTTOM_TOOLBAR = '{user}@{hostname}'

# Custom fields
$PROMPT_FIELDS['kube'] = lambda: $(kubectl config current-context).strip()

# Colors: {GREEN}, {BOLD_BLUE}, {#ff88aa}, {BACKGROUND_RED}, {bg#0012ab}
# Conditional: {curr_branch: [{}]} — shows "[main]" or nothing
```

## Xontribs

```python
xontrib load vox                    # virtual env manager
xontrib load z                      # directory jumping
xontrib load coreutils              # Python coreutils
xontrib load abbrevs                # fish-like abbreviations
xontrib load whole_word_jumping     # ctrl+left/right
xontrib load coconut                # coconut functional syntax in shell
```

### Writing a xontrib

```
xontrib-myext/
  pyproject.toml      # entry point: [project.entry-points."xonsh.xontribs"]
  xontrib/myext.py    # runs in xonsh context on load
```

```python
# xontrib/myext.py
from xonsh.built_ins import XSH
from xonsh.events import events

XSH.aliases['myalias'] = 'echo hello'

@events.on_chdir
def _on_chdir(olddir, newdir, **kw):
    pass
```

## Foreign shell integration

```python
source-bash ~/.bashrc               # import env + aliases from bash
source-zsh ~/.zshrc                 # from zsh
source file.xsh                     # source xonsh files
```

## Scripts

```python
#!/usr/bin/env xonsh
# deploy.xsh
$RAISE_SUBPROC_ERROR = True
import sys
env = sys.argv[1] if len(sys.argv) > 1 else 'staging'
echo @(f"Deploying to {env}...")
git pull origin main
```

`.xsh` scripts don't load `rc.xsh`/`.xonshrc`. They have full language features but no `edit:` namespace (that's interactive only via prompt_toolkit).

## Gotchas

- `&&` and `||` work in subprocess mode (modern xonsh) but are boolean `and`/`or` in Python mode
- Backticks are globs, not command substitution (use `$()` for that)
- `$()` strips trailing newlines; use `!()` for exact output
- `source` runs xonsh code; use `source-bash` for bash scripts
- `for f in *.py; do ... done` is bash syntax; use `for f in g`*.py`: ...`
- Check command existence with `import shutil; shutil.which('cmd')` not `which`
