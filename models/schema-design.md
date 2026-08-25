# Schema design

Prose companion to the Forge models in this directory. The models say what is
true; this says what we are building and why. Where a claim here is checked by a
model, the test is named. Where it is not, that is said plainly.

Status: design, not yet built. Written 2026-08-25.

## 1. What this is

A personal knowledge and task system in which:

- a single graph of nodes and edges is the durable representation,
- markdown is a projection of that graph, not its storage format,
- an olog is a *contract over a subgraph*, not a schema imposed on everything,
- and everything above the graph is regenerable.

The system is described in the same language it uses to describe its contents:
providers, verbs, schemas and stores are nodes like any other.

## 2. Layering

    category      composition, associativity, unitality        category.frg
    presentation  generators (graph) + relations (facts)       olog.frg
    instance      an assignment of data to the presentation    the store
    projection    natural transformations out of the instance  markdown, prompts

The graph is a *presentation of a category*: nodes and edges are the generators,
declared path equivalences are the relations. A presentation carries only partial
composition — the composites it names. This is not a simplification. Requiring
total composition would require a finite store to contain an infinite category,
because a cycle in the graph generates infinitely many formal composites before
the declared facts collapse them. See the header of `olog.frg`.

### 2.1 Three kinds of constraint, deliberately separated

**Path equivalences** — two composites are equal. These shape the category and
belong in Forge. There are exactly two at present:

    resolve . identify = id      an identifier is a key
    parse   . render   = id      a record survives the round trip

Both are split monomorphisms, and both are already proven by
`factsForceInjectivity` in `olog.frg`. Neither is re-derived. The second is
instantiated for rendering in `rung6-projection.frg` as `renderIsInjective`.

**Shape predicates** — a node of kind K must have field F; relation R may only
connect kinds A and B. These do not shape the category; they cut down which
assignments count as admissible instances. They belong in Nickel.

**Everything else** — "a completed task has no incomplete blockers" — is a
policy. Also Nickel, but distinguishable from a shape predicate in that
violating it is a state of the world rather than a malformed record.

Conflating the first two was a mistake made and corrected during design. The
test for which bucket a rule belongs in: does it equate two composites?

## 3. The graph

One node type. One edge type. No schema at the storage layer.

    a node ── has as kind ─────▶ a kind
    a node ── has as text ─────▶ a line of text
    an edge ─ has as source ───▶ a node
    an edge ─ has as target ───▶ a node
    an edge ─ has as relation ─▶ a relation

Task, note and event (after Ryder Carroll) are kinds, not types. Status, dates,
signifiers, blocking and migration are kinds, relations or predicates. Nothing
requires a new sig.

The cost of a single node type is real and is accepted knowingly: an olog draws
its strength from typed boxes, and a single-typed presentation puts all content
into the relations. The type discipline does not disappear — it relocates from
the storage shape into predicates, which is the RDF failure mode if the
predicates are not enforced. The mitigation is section 8: validation is a
standing query over the whole store, not a gate at write time.

The gain is that cross-domain edges are expressible without a join. A task can
block a pipeline stage; a note can motivate a skill; an atom can cite a
transcript. With separate type universes each of those needs a decision about
which side owns the relation. With one, it is an edge.

### 3.1 Non-functional relations are spans

A relation that is not single-valued — a task blocks several tasks — is not an
aspect. Following Spivak & Kent §2.2.3 it is a span: a node with a projection
per leg. In relational terms this is a junction table, which is the same
construction under a different name.

## 4. Stores and roots

A layer must persist when it cannot be regenerated. `rung8-persistence.frg`
examines this and refutes the clean statement of it in two ways worth knowing:

1. The biconditional "must persist iff not deterministically reachable from a
   persisted layer" holds **only under acyclicity of deterministic arrows**. A
   cycle of mutually derivable layers has no canonical member, and reachability
   cannot choose one. Witness: `rootPlacementFailsOnDeterministicCycles`.
   Consequence: **roots are declared, never inferred.**
2. The root is not unique. It is a non-empty *set*, all of which persist.
   Witness: `certifiedRootIsNotUnique`, `everyCertifiedRootPersists`.

Four stores, distinguished by why they persist:

| store   | persists because             | writer | shape                  |
|---------|------------------------------|--------|------------------------|
| capture | nothing maps into it         | human  | files, immutable       |
| ledger  | the arrow into it is random  | model  | append-only, all channels |
| graph   | folded from an append log    | both   | entries → nodes, edges |
| config  | authored                     | human  | Nickel source          |

A store is itself a declared record — a node of kind `store` — carrying: root
kind, append discipline, anchor scheme, retention policy, location, writer. The
declaration *is* the root designation, which is what finding (1) above requires.

Retention differs per store by design. History and sessions were always going to
want different garbage collection; making the policy a field rather than a
behaviour is what allows that.

### 4.1 Snapshots are a third category

A **view** is regenerated on demand and disposable. A **snapshot** is a view
deliberately frozen, and freezing buys what regeneration cannot: git history over
the projection, sync to devices with no tooling, readability by anything that
reads markdown, and — because `parse . render = id` — a redundant encoding of the
store. If the store is lost, the snapshot reconstructs it. The split
monomorphism is what makes the vault a backup rather than only a display.

The hazard is two independent histories of one evolution: git over the snapshot,
and the entry log over the store. They diverge whenever the vault is edited
without the store present, which is the ordinary case on a phone. Therefore the
vault is not merely an authoring surface but an **authoritative writer**, and
ingestion — parse, tag with provenance, reconcile per record — is how those
writes enter the graph. Reconciliation is per record rather than per file
precisely because parse recovers records.

## 5. Projections and audience

Three transformations out of one store, with different obligations:

| audience | register                        | must round-trip |
|----------|---------------------------------|-----------------|
| model    | terse, established vocabulary   | no — it is a wire |
| author   | prose with visible identifiers  | **yes**         |
| others   | plain prose, no machinery       | no — deliberately |

Only the projection you edit carries an injectivity obligation. Published
artifacts — a README, documentation in a project repository — are one-way and
allowed to be lossy; that is the point of them. They are handed to *another
root*, which versions them, and edits made there do not flow back. The graph
records a one-way provenance edge (`published to repo@commit at time T`) so that
the question "which of my published documents are stale" is answerable without
pretending the published copy is still ours.

On the model-facing register, empirically (see section 11): **coined
abbreviations do not survive a hop between contexts; established technical
vocabulary does.** Compression should be lexical selection from vocabulary the
model already has, not private encoding. A node that coins must re-declare what
it forwards, since a node is otherwise only obliged to declare what it
originates — the mechanism is isolated in `rung7-graph.frg` as
`honestAboutOwnOutput`.

## 6. File format

MyST is adopted as a **carrier grammar**, not for its directive vocabulary. What
is wanted from it: a published, versioned AST (mdast plus extra node types) and a
conformance corpus (`myst.tests.json`) to test a parser against. The directive
names are ours; unknown names parse structurally and expose `name`, `args`,
`options`, `value`.

Empirically verified against the current parser:

- headings **cannot** carry attributes; `## H {#id k=v}` leaves the braces as text
- there is **no section node**; headings are flat siblings with `depth`
- there is no generic block-attribute syntax and no fenced divs
- `(label)=` carries an identifier and nothing else
- **`+++ {json}` carries arbitrary JSON, and every key survives into `block.data`**
- directive options survive on the raw node before transforms run

### 6.1 Two carriers

**`+++` for prose with metadata.** A block break is a node boundary.

    +++ {"id": "n-4f2a", "kind": "note", "topic": "projection"}

    ## Markdown is a projection

    Ordinary prose. Headings, lists, links — all native.

Its scoping is sequential rather than hierarchical. That is a fit rather than a
limitation: hierarchy in this system is an edge, not containment.

**Directives for data with a body**, where the metadata is the content:

    ```{task} write the myst parser
    :id: t-4f2a
    :status: open
    ```

Both round-trip; the choice is which reads better.

Caveat to carry forward: `+++` is MyST's notebook-cell heritage and its declared
meaning is "block break". Using it as a node boundary is our convention layered
on their syntax. A future version could give block metadata semantics we do not
want.

### 6.2 Shape carries structure; fields carry identity and state

The AST is already typed. Heading depth folds deterministically into a
containment tree, so the absent section node costs nothing. Lists are
collections. **Links are already edges** — `[text](target)` and `[[wikilink]]`
become graph edges with no additional syntax, which means the vault's existing
linking behaviour is the graph.

Explicit fields are therefore needed only where there is no structural
correlate: identifier, kind, status.

The rule, and the reason for it: structure inferred from shape is *stable under
the edits that should change it* — promoting a heading legitimately changes
containment. Identity and state are not. Any schema that infers status from
position ("tasks under the Done heading are done") corrupts silently on a
reorganise. Structure, yes. State, never.

### 6.3 Identifiers are written into the artifact

Rung 6 establishes that deterministic regeneration requires one stable
identifier per *connected component* — not one per record, and not none.
`naturalityAloneDoesNotDetermineTheProjection` is the counterexample to the
weaker claim; `naturalityDeterminesTheProjectionFromARoot` is what survives.

Because a file may be edited on a device that has never seen the store,
identifiers must be present in the file itself and globally unique — qualified
by store, since a synced file has no other way to say where it came from.

## 7. Schemas as functors

A schema is a reading of the AST: a functor from AST shapes to node kinds and
relations. Under one schema an `h2` inside a task block is a subtask; under
another, list items beneath a "References" heading are citation edges. Same file,
same AST, different instances.

This indexes the round-trip law: it is `parse_S . render_S = id` **for each
schema S**, each with its own anchor set. The theorem of rung 6 is unchanged; it
acquires a parameter that had been left implicit.

Parse pipeline:

    text → MyST AST → fold headings into containment
         → apply schema S → nodes + edges
         → merge explicit fields from +++ and directive options

## 8. Validation

Contracts are checkable **at rest**, over the whole store, rather than only at
write time. This is what makes the store safe for a model to write into: the
answer to "is my store well-formed" is a standing report, not a gate.

Under the relational reading, the checks are dataframe operations rather than
graph traversals:

| relational        | categorical                       |
|-------------------|-----------------------------------|
| schema            | a category                        |
| instance          | a functor to Set                  |
| table             | an object; rows are its elements  |
| foreign key       | an aspect — total, single-valued  |
| primary key       | the anchor                        |
| join along a key  | composition                       |
| natural join      | pullback                          |
| junction table    | a span                            |

Checking that a declared aspect is an aspect is a group-by:

    edges | where relation == A | group-by source | where count != 1   # must be empty

Checking a fact is a join followed by an anti-join for the difference.

Known impedance mismatches: SQL is bags where Set is sets, so duplicate rows have
no counterpart; and `NULL` is partiality, which an aspect forbids by definition —
a nullable foreign key is a span, not an aspect.

## 9. Digestion

Conversation accumulates in the ledger. Periodically — not per turn — a pass
turns ledger content into atoms in the graph. Batching is an economic decision:
extraction is the expensive stochastic arrow, and a finished session has a shape
a single turn does not. It is also Carroll's migration: deliberate friction as
the filter, run on a rhythm.

Context for a future request is then a **query against the graph**, not a stored
payload. Store the query, not the result: the query is authored, so it is config;
the result is a view, so it is disposable.

Two consequences:

1. A scope of work is simultaneously the query boundary and the **cache
   boundary**. A fold stable for the duration of a project can be a pinned
   prefix at one tenth the token cost; a fold that churns cannot. Scopes should
   be carved for stability, not only for tidiness.
2. An ephemeral fold becomes durable the moment it is sent, because the ledger is
   immutable. Today's view is tomorrow's raw data. Therefore a ledger entry
   records not only the messages but **the query that assembled them** — without
   which "what did it actually know" is unanswerable.

## 10. What is deliberately absent

- The pipeline runtime. `rung7-graph.frg` models the graph of pure and agent
  nodes; nothing executes it yet. The routing is done by hand.
- Output, reasoning and fan-out budgets. These are quantities, not structure, and
  are not representable in an olog; `rung9-capability.frg` says so in its header.
  They are fields on a verb.
- A faithful plan. `rung9` proves monotonicity of the build list under capability
  addition, but only because fact preservation is stated existentially. A plan
  required to *reflect* facts as well as preserve them would lose monotonicity.
  Left unbuilt rather than half-built.
- Any claim above the solver's bounds. Forge is a bounded model finder, not a
  proof checker. Every `is unsat` here means "no counterexample within these
  bounds" — typically four to eight atoms per signature. The small-scope
  hypothesis is an empirical claim about where flaws live, not a theorem.

## 11. Empirical results informing this design

From a pipeline run by hand on 2026-08-25: two source notes compressed
independently, joined two ways, translated back to prose by blinded readers.
Roughly 220,000 tokens across seven agents.

- **Sequential depth, not sequential composition, is what costs.** The
  alternating arm lost 18 of 27 inherited abbreviations; the parallel arm lost
  about 12, none inherited. `rung7-graph.frg` refutes the stronger claim that the
  tensor prevents leakage: `tensorLegThatIsItselfAChainStillLeaks` is
  satisfiable. The tensor helps only insofar as it trades depth for width.
- **Content was robust; encoding was not.** The substantive conclusion crossed
  both topologies intact while the shorthand carrying it did not.
- **Instructions describing a register underperform examples in it.** The brief
  was verbose prose asking for terseness, and both agents underperformed. An
  instruction is a claim about the output distribution; an example is a sample
  from it.

## 12. Open questions

- Whether identifiers are globally store-qualified, or local with cross-store
  edges as a distinct relation. The first is more honest to rung 6; the second is
  less work. Not decided.
- Whether the graph fold is recomputed per query or materialised alongside the
  log. Materialising is safe — it is a view, so it can never be authoritative —
  but is not needed until it is slow.
- Whether rung 7's pipeline category and the store's presented category relate,
  or merely coexist. Genuinely open; asserting a connection would be unchecked.
- Whether the vault reconciliation is three-way (store, snapshot, edit) and what
  wins on conflict. Not modelled.

## 13. Build order

Deliberately LLM-free first, so that everything checkable is checked before
anything stochastic touches the store.

1. Store: append-only entry log; fold entries into nodes and edges.
2. Nickel: `Node`, `Edge`, `Kind`, `Relation`; `Task`/`Event`/`Note` as
   predicates over kind; `Olog` as a contract over a subgraph.
3. Projection: nodes → MyST.
4. Parser: the `+++` and directive scanner in nushell.
5. The test: `render | parse` equals the store.

The parser is replaceable behind that equation, but the Rust rewrite is not
currently worth it, and the investigation changed what it would look like.

- A **nushell plugin is the wrong shape**. Plugin compatibility is a caret check
  on `nu-plugin-protocol`, and since nushell is 0.x that matches only the exact
  minor. Nushell ships a minor roughly monthly, so every upgrade means recompile
  and re-register on every machine, and a mismatch fails to load rather than
  degrading. If a binary is ever wanted it should be a plain CLI reading stdin
  and writing JSON: ~2-5ms startup, invisible unless called in a tight loop, and
  no version coupling at all.
- **`rushdown` is too young.** Created 2026-03-04; twenty-four releases from
  v0.9 to v0.18 in about eight weeks; every "third-party" extension is the
  author's own. Its extension API is the nicest of the alternatives and its
  fenced-div extension is close to the shape a directive needs, but an API that
  moves every three weeks is a liability. Revisit at 1.0 with a stability policy
  and an extension author who is not the maintainer.
- **A parser extension is not needed anyway.** A MyST directive is already a
  valid CommonMark fenced code block with the info string `{name} arg`, so any
  parser yields it; the `:key: value` lines are a regex over the body. `+++` is a
  line-level document splitter applied before parsing. Wikilinks are native in
  `pulldown-cmark` and `comrak`.

### 13.1 Prose is opaque

Every Rust markdown renderer normalises on output — bullet markers, emphasis
characters, indentation, link reference style. Rendering a parsed AST back to
text would therefore *break* `parse . render = id`.

The rule that avoids this, and which holds whatever parser is used: **body text
is stored verbatim and re-emitted byte for byte; it is never parsed into an AST
and re-serialised.** The AST is read-only, used to extract structure — heading
depth, links, list shape — into edges and query material. Under this rule the
round trip is safe by construction rather than by the good behaviour of a
renderer.
