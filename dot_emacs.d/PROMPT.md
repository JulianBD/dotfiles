Project: Emacs Config Contract Framework
You are helping build two related but separate artifacts in a single repository:

A personal Emacs configuration — minimal, opinionated, vanilla-biased
A package that defines a contract framework for expressing Emacs configuration as schema-validated data

These artifacts must be developed with strict separation of concerns. Conflating them will undermine the project.

The Contract Framework (the package)
What it is
A mechanism for defining, validating, and applying Emacs configuration as data. It provides:

A macro/function for declaring atoms (units of configuration) with schemas
A loader that reads data files conforming to those schemas and applies them
A pluggable projection layer so data files can be in any serialization format (initial reference implementation in restricted S-expressions)
An extraction tool that walks a package's prefix namespace and surfaces candidate atoms from its def* forms

Invariants

The config data layer permits no user-authored computation. Users cannot write lambdas, defuns, or any expression requiring evaluation inside the config file. References to named, existing functions are permitted (they are data — symbols that resolve via lookup). The line is "no user authorship of code inside the config," not "no references to computation."
Atoms are atomic. A keybinding is one atom. A hook registration is one atom. A mode association is one atom. Atoms do not subsume each other. Package declarations compose atoms; they do not replace them.
The contract is orthogonal to the projection. The atom schema defines what an atom is. The projection defines how it's serialized. Multiple projections can exist for the same contract.
The framework adds, never subtracts. Raw Elisp configuration continues to work unchanged. The framework is opt-in at every level — per atom, per package, per user.
Enforcement is at the parser level, not by convention. The loader uses read, not eval. Forms that would require evaluation to produce a value fail schema validation by construction.

Design anti-patterns to avoid

Don't build a restricted programming language. CUE, Jsonnet, Dhall, Nickel are all cautionary examples. The config is data, not a language.
Don't design monolithic units (modules in the Doom sense). Atoms must compose freely.
Don't infer a package's configuration surface from its source without human review. The extractor produces candidates; a curator produces the manifest.
Don't require package authors to do anything new. Manifests can be user-contributed for packages whose authors haven't participated.


What an atom is
An atom is the unit of configuration. It is:

A configurable base type with a declared schema (fields, types, defaults, documentation)
Composable — larger configurations are compositions of atoms, not subsumptions of them
Data — an atom instance is a data structure, not a form requiring evaluation
Addressable — atoms have stable identities so they can be referenced, overridden, and merged
Pluggable at the application boundary — the same atom can apply to different targets (vanilla Emacs, a specific package, a user-defined extension) via registration

An atom has two sides:

The schema side — what the atom looks like as data. What fields it has, what types those fields take, what defaults exist, what values are valid.
The application side — how instances of the atom translate into Emacs state. What gets called, on what, in what order, with what arguments.

These sides are separate concerns and should be designed separately.
Examples (illustrative, not final)
A keybinding atom might have fields like: a key sequence, a command reference (symbol naming an existing function), and an optional scope (global, a mode name, or a keymap reference). Its application side calls the appropriate Emacs keybinding mechanism for the scope.
A hook registration atom might have fields like: a hook name (symbol) and a list of function references (symbols). Its application side calls add-hook for each function.
A mode association atom might have fields like: a pattern (regex or string) and a mode name (symbol). Its application side updates auto-mode-alist.
A variable setting atom might have fields like: a variable name (symbol) and a value (data, typed according to the variable's declared type if discoverable). Its application side calls setq or the appropriate custom-setter.
A face customization atom might have fields like: a face name (symbol) and a spec (structured data describing foreground, background, weight, etc.). Its application side calls set-face-attribute or the equivalent.
These are starting candidates. The real set emerges from walking the user's actual config and minimal-starter prior art.
Open design questions about atoms
The following are intuitions to work out, not settled answers. Treat them as the hard problems to solve, not as specifications to implement.

Registration model. The intuition is registration-by-annotation: an atom is declared in Elisp (likely via a macro), which registers its schema with the framework and associates it with an application function. The annotation both documents the atom and wires it to where it takes effect. Details to work out: what the annotation syntax looks like, how application functions are bound, whether annotations can be extended or overridden after initial registration.
Pluggability of application. The same atom (e.g., a keybinding) may need to apply differently depending on target — vanilla Emacs uses global-set-key, a specific mode needs define-key on its keymap, a package might provide its own binding helper. The intuition is that the application side is pluggable per atom instance or per target, not hardcoded per atom type. Details to work out: how targets are declared, how the framework dispatches to the right applier, how conflicts or ambiguities are handled.
Composition semantics. When multiple atoms touch related state (e.g., two keybinding atoms bind the same key in different scopes, or a package's atom manifest declares a default that the user's config overrides), what are the merge rules? This is where Nix module systems have well-developed answers worth studying — not necessarily adopting, but understanding.
Atom identity and addressability. For atoms to be composable and overridable, they need stable identities. What makes two atom instances "the same" for purposes of override? Is it the atom type plus a key field? The full content? Something declared explicitly per atom type?
Scope and layering. Atoms likely need a notion of where they come from (user config, package manifest, framework default) and how those sources compose. Nix module systems treat this as option merging with priorities; figure out what the analog is here.


The Personal Configuration (the config)
What it is
A minimal Emacs configuration, vanilla-biased, that doubles as the reference implementation of the framework and the initial corpus for atom extraction.
Invariants

Content comes from personal use, validated against minimal-starter prior art. Draw on Prot's configuration for structural discipline (not content), and Minimal/Bedrock for content validation (not structure). Borrow dimensions from different sources; do not inherit whole approaches.
Vanilla-biased. Prefer Emacs built-ins where possible. Delegate to external packages only when a built-in approach is genuinely inadequate, and only to ubiquitous packages (roughly: as common as use-package or magit).
Grounded in real use. The initial atom list is derived from what the user actually configures. Not aspirational, not comprehensive.
Every atom in the config exists because the user uses it. If the user doesn't use it, it doesn't go in the MVP, regardless of how "standard" it seems.

Separation from the framework

The config uses the framework but is not part of it.
The framework must be installable and usable by someone who doesn't adopt the config.
The config must be comprehensible to someone reading it without the framework package loaded (even if it wouldn't apply correctly).
Changes to the config should not drive framework API changes except through explicit design conversations.


Layer Map
┌─────────────────────────────────────────────────────────┐
│ User's data file (projection: S-exp / TOML / etc.)      │  ← what the user edits
├─────────────────────────────────────────────────────────┤
│ Projection layer (parser + serializer)                  │  ← pluggable
├─────────────────────────────────────────────────────────┤
│ Atom schemas + validator                                │  ← the contract
├─────────────────────────────────────────────────────────┤
│ Atom registry (built-in atoms + user/package manifests) │  ← the extensible core
├─────────────────────────────────────────────────────────┤
│ Applier (data → Emacs state, pluggable per target)      │  ← the Elisp escape
├─────────────────────────────────────────────────────────┤
│ Vanilla Emacs + delegated packages                      │  ← the substrate
└─────────────────────────────────────────────────────────┘
Changes at one layer must not leak into others. Specifically:

Projection changes must not require atom schema changes
Schema changes must not require applier changes for unrelated atoms
Applier changes (how an atom's data becomes Emacs state) must not affect the atom's schema or data representation


Starting Sequence
Work in this order. Do not jump ahead without completing the prior step.

Enumerate the user's actual configuration needs — what the user currently configures or would configure in Emacs. List each one, note whether vanilla Emacs handles it or whether a ubiquitous package is required.
Survey minimal starters — read through Prot, Bedrock, Minimal. Extract structural conventions from Prot; validate the atom list against Bedrock/Minimal.
Work through the open atom design questions — registration model, pluggability of application, composition semantics, identity, scope/layering. Produce a design document that takes positions on each. This precedes schema writing.
Draft the atom schemas as pure data specifications, independently of any implementation. Write these as a spec document before writing code.
Build the minimum loader and validator that can consume data conforming to the schemas and apply them. S-expression projection only.
Use it to replace the user's actual Emacs config. If it can't, the atoms are wrong or the framework is missing something load-bearing. Find out now.
Then, and only then, build the extraction tool for surfacing candidate atoms from package prefix walks.


What this project is not

Not a replacement for use-package, leaf, or setup.el. Those are Elisp-sugar for authoring Elisp config. This is a data-layer contract.
Not a Doom/Spacemacs competitor. Those ship opinions as bundled modules. This ships a contract that users and packages can extend.
Not a new config language. There is no language. The data layer is data.
Not a rewrite of Emacs or a fork. It's a package that runs inside standard Emacs.
Not a criticism of Elisp. Elisp remains essential. The framework externalizes the portion of config that's implicitly declarative, so the Elisp layer can focus on the portion that's genuinely computational.


Principles for working on this

When in doubt, exclude. The value of the contract comes from what it refuses to include.
Prefer explicit failure over implicit coverage. An extractor that says "I don't handle this" is better than one that silently produces wrong results.
Ground design decisions in real atoms from the user's real config. Hypothetical users lead to over-engineered abstractions.
Legibility over completeness. The contract is worth something if it covers 60% of real needs cleanly; it's worth nothing if it covers 100% of needs messily.
Hold the no-computation line. Every time pressure builds to add "just a small escape hatch" for some common case, the right answer is to name an existing function in Elisp and reference it from the data.
