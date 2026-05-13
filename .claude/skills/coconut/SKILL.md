---
name: coconut
description: Write, debug, and reason about Coconut functional programming code (.coco files). Coconut is a strict superset of Python that adds Haskell/OCaml-style features — pipes, pattern matching, algebraic data types, partial application, function composition, lazy evaluation — and compiles to pure Python. Use when the user is working with .coco files, mentions coconut-lang, or writes functional Python using pipe operators, `data` declarations, `addpattern`, `match`/`case` on pre-3.10 Python, or coconut-specific syntax. Also trigger when the user loads the coconut xontrib in xonsh.
argument-hint: [what to do]
---

## What Coconut is

Coconut (coconut-lang) is a strict superset of Python 3 — all valid Python is valid Coconut. The `coconut` compiler transpiles `.coco` files to pure `.py` files. Every Python package works via normal `import`. Current version: v3.2.0.

Install: `pip install coconut`
Compile: `coconut myfile.coco` produces `myfile.py`
REPL: `coconut` with no args
Xonsh integration: `xontrib load coconut`

## Pipeline operator (`|>`)

The signature feature. Replaces nested calls with left-to-right data flow.

```coconut
# Instead of: list(map(lambda x: x**2, range(10)))
range(10) |> map$(.**2) |> list

# Multi-line pipelines
data = (
    raw_input
    |> .strip()
    |> .split(',')
    |> map$(int)
    |> list
)
```

### Pipe variants

| Operator | Meaning |
|----------|---------|
| `\|>` | Pipe: `x \|> f` = `f(x)` |
| `\|*>` | Star pipe: `x \|*> f` = `f(*x)` |
| `\|**>` | Double-star pipe: `x \|**> f` = `f(**x)` |
| `<\|` | Back pipe: `f <\| x` = `f(x)` |
| `<*\|` | Back star pipe |
| `<**\|` | Back double-star pipe |

## Partial application (`$`)

```coconut
add1 = (+)$(1)              # partial application of +
double = (*)$(2)
map$(.**2)                  # partial with operator section

# Named argument partials
f = func$(x=1)              # fix keyword arg
```

## Operator sections

Reference operators as functions:

```coconut
(+)                         # addition function
(*)                         # multiplication function
(.)                         # attribute access
(+)$(1)                     # add-one function
(.**2)                      # square function (implicit partial)
```

## Pattern matching

Full pattern matching on all Python versions, not just 3.10+.

```coconut
match command:
    case "quit":
        exit()
    case "go" in direction:
        move(direction)
    case ["drop", *items]:
        drop(items)

# With guards
match x:
    case int() if x > 0:
        print("positive")
    case int():
        print("non-positive")
```

### Destructuring

```coconut
match (1, 2, 3):
    case (a, b, c):
        print(a, b, c)     # 1 2 3

match {"key": value, **rest}:
    case {"key": v}:
        print(v)
```

## Algebraic data types (`data`)

Immutable, destructurable types like Haskell's `data` declarations.

```coconut
data Empty()
data Leaf(n)
data Node(l, r)

# With methods
data Vector(x, y):
    def __abs__(self):
        return (self.x**2 + self.y**2)**0.5

# Usage
tree = Node(Leaf(1), Node(Leaf(2), Leaf(3)))
```

ADTs are immutable namedtuple-like classes. They support pattern matching, have auto-generated `__eq__`, `__repr__`, `__hash__`, and are hashable.

## Multi-clause functions (`addpattern`)

Build functions from multiple pattern-matched clauses, like Haskell equations.

```coconut
def factorial(0) = 1
addpattern def factorial(n) = n * factorial(n - 1)

def size(Empty()) = 0
addpattern def size(Leaf(_)) = 1
addpattern def size(Node(l, r)) = size(l) + size(r)
```

## Assignment functions

Concise single-expression function definitions.

```coconut
def double(x) = x * 2
def add(x, y) = x + y
```

## Function composition

```coconut
# Forward composition
process = .strip() ..> .split() ..> len
# process("  hello world  ") == 2

# Backward composition
process = len <.. .split() <.. .strip()
```

## Lazy evaluation

### Lazy lists

```coconut
(| 1, 2, 3, 4 |)           # lazy — items evaluated on demand
```

### Iterator chaining (`::`)

```coconut
# Lazy concatenation, can build infinite sequences
naturals = 1 :: naturals |> map$(+ 1)

# Take from infinite sequence
naturals$[:10] |> list      # [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

### Iterator slicing (`$[]`)

```coconut
range(100)$[10:20]          # lazy slice, no intermediate list
naturals$[::2]              # every other natural number (lazy)
```

## Infix notation

Use any function as an infix operator with backticks.

```coconut
5 `mod` 3                   # mod(5, 3)
[1,2] `zip` [3,4]           # zip([1,2], [3,4])
```

## `where` clauses

```coconut
result = hypotenuse(a, b) where:
    a = 3
    b = 4
    def hypotenuse(x, y) = (x**2 + y**2)**0.5
```

## Built-in functional tools

Coconut adds many builtins beyond Python's:

```coconut
# reduce (no import needed)
[1, 2, 3, 4] |> reduce$(+)         # 10

# fmap — generic functor map
fmap(f, container)

# ident — identity function
ident(x)                             # x

# const — constant function
const(1)(anything)                   # 1

# flip — flip first two args
flip(f)(a, b) == f(b, a)

# lift — lift a function to work on containers
lift(+)(Just(1), Just(2))            # Just(3)

# scan — like reduce but yields intermediate results
[1, 2, 3, 4] |> scan$(+) |> list    # [1, 3, 6, 10]

# takewhile, dropwhile, groupby, tee, count, cycle, repeat
# starmap, zip_longest, product, combinations, permutations
# All available without importing itertools
```

## Python interop

All Python works as-is. Import any pip package normally.

```coconut
import numpy as np
from pathlib import Path
import requests

data = requests.get("https://api.example.com").json()
result = data["values"] |> np.array |> np.mean
```

### Accessing Coconut builtins from Python

```python
from coconut.__coconut__ import reduce, scan, fmap
```

## Compilation

```bash
coconut myfile.coco              # produces myfile.py
coconut myfile.coco --target 3.12 # target specific Python version
coconut --package src/            # compile directory, include runtime
coconut --no-tco                  # disable tail call optimization
coconut --mypy                    # type-check with mypy after compile
```

### Programmatic compilation

```python
from coconut.convenience import parse
python_code = parse("range(10) |> map$(.**2) |> list")
```

## Type system

Coconut supports latest Python type annotation syntax on all versions (compiles to version-independent form). Has built-in mypy integration.

```coconut
def add(x: int, y: int) -> int = x + y

data Point(x: float, y: float):
    def distance(self, other: Point) -> float =
        ((self.x - other.x)**2 + (self.y - other.y)**2)**0.5
```

## Xonsh integration

With `xontrib load coconut` in `.xonshrc`, Coconut syntax works directly in the xonsh shell:

```
$ range(10) |> map$(.**2) |> list
[0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
```

This combines shell command execution with functional data pipelines.

## Common patterns

### Null-safe chaining with `?.`

```coconut
result = obj?.attr?.method()     # None if any step is None
```

### Tail call optimization

Coconut optimizes tail-recursive functions automatically.

```coconut
def factorial(n, acc=1):
    match n:
        case 0: return acc
        case _: return factorial(n-1, n*acc)  # TCO'd
```

### Protocol-oriented data processing

```coconut
data CSV(headers, rows):
    def filter_by(self, col, pred) =
        CSV(self.headers, [r for r in self.rows if pred(r[self.headers.index(col)])])
    def select(self, *cols) =
        CSV(cols, [[r[self.headers.index(c)] for c in cols] for r in self.rows])
```

## Gotchas

- Coconut's `|>` binds tighter than Python's `|` (bitwise OR) — parenthesize if mixing
- `$` for partial application is not the same as xonsh's `$` for env vars — context determines which
- `.method()` as an operator section (like `.strip()`) only works in Coconut, not Python mode
- `match`/`case` in Coconut works on all Python versions but compiles differently than Python 3.10+ native match
- `data` types are immutable — use `._replace()` for functional updates
- Iterator slicing with `$[]` consumes the iterator up to that point
- Tail call optimization works but has overhead — don't use for non-recursive hot loops
