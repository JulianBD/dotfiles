#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#set page(width: 17cm, height: auto, margin: 1.4cm)
#set text(size: 10pt)
#set par(justify: true)
#show raw.where(block: true): it => block(
  fill: luma(247), inset: 8pt, radius: 3pt, width: 100%, it,
)

// Excerpts are cut from the model at compile time, between two literal
// anchors, so they are verbatim by construction. A renamed sig breaks the
// build rather than silently leaving this document quoting code that is gone.
#let model = read("olog.frg")
#let excerpt(from, to) = {
  let start = model.position(from)
  if start == none { panic("olog.frg has no anchor: " + from) }
  let stop = if to == none { model.len() } else { model.position(to) }
  if stop == none { panic("olog.frg has no anchor: " + to) }
  raw(model.slice(start, stop).trim(), block: true)
}

= olog.frg, walked through

A Forge encoding of the olog, after Spivak & Kent, _Ologs: A Categorical
Framework for Knowledge Representation_ (arXiv:1102.1889). This document walks
the model in the order it is written; every code block below is cut from
`olog.frg` itself at compile time.

An olog is a category whose objects are *types* (§2.1, boxes labelled with a
singular indefinite noun phrase) and whose arrows are *aspects* (§2.2, drawn
from a domain of definition to a set of result values). Definition 3.2.3 gives
the semantics this model checks.

== Turning the visualiser off

#excerpt("// Tests are the whole point", "// §2.1 A type")

The file is all `test expect` and no `run`, so there is nothing to look at.
Without this option Forge opens Sterling and blocks on standard input when the
run finishes, which is indistinguishable from a hang.

== A type

#excerpt("// §2.1 A type", "// §2.2 An aspect")

Empty, and deliberately so. A type in the paper is a box carrying English text,
but the text is the one part a solver cannot check: "begins with 'a' or 'an'"
and "refers to a distinction made and recognizable by the author" are rules for
the author. What remains after the label is removed is bare identity, which is
exactly `sig Type {}`.

== An aspect

#excerpt("// §2.2 An aspect", "// §3.1.1 An instance")

`dom` and `cod` are the paper's own words — §2.2 calls $X$ "the domain of
definition" and $Y$ "the set of result values". `act` is the aspect's action on
instance data, and it is a `set Element -> Element` rather than a function
because Forge has no function type here; the constraint that makes it a
function lives in `functorial`.

== An instance of a type

#excerpt("// §3.1.1 An instance", "// §3.2.3 The functor law")

The comment records a modelling decision worth being explicit about, since it
is a place where the encoding is narrower than the paper.

== The functor law

#excerpt("// §3.2.3 The functor law", "test expect {")

Three clauses, and they are the paper's own two rules for a function (§2.2:
"each arrow must emanate from a dot in $X$ and point to a dot in $Y$"; "each dot
in $X$ must have precisely one arrow emanating from it") split into the parts
Forge needs stated separately. Clause one is totality and single-valuedness on
the domain, clause two forbids an aspect acting outside its domain, clause three
is the typing of results.

This predicate is the entire content of the sentence "an aspect is a functional
relationship". Everything the model can say about validity, it says here.

== The typing clause, drawn as a fact

Clause three is a path equivalence, so it can be drawn the way the paper draws
facts (§2.3). Take the type of pairs $(a, e)$ where $a$ is an aspect and $e$ is
an element of its domain. Two paths lead from there to a type, and the fact
asserts they agree:

#align(center, diagram(
  spacing: (46mm, 18mm),
  node-inset: 6pt,
  node((0, 0), [a pair $(a, e)$ where $a$ is\ an aspect and $e$ is an\ element of its domain], stroke: 0.5pt, name: <P>),
  node((1, 0), [an element], stroke: 0.5pt, name: <E>),
  node((0, 1), [an aspect], stroke: 0.5pt, name: <A>),
  node((1, 1), [a type], stroke: 0.5pt, name: <T>),
  edge(<P>, <E>, "->", label: [yields, via `act`], label-side: right),
  edge(<E>, <T>, "->", label: [`isa`], label-side: right),
  edge(<P>, <A>, "->", label: [`aspect`], label-side: left),
  edge(<A>, <T>, "->", label: [`cod`], label-side: right),
  node((0.5, 0.5), text(1.3em)[✓]),
))

Read the paths aloud, as the paper instructs. Clockwise: "a pair $(a, e)$
yields, via `act`, an element, which is a type." Anticlockwise: "a pair $(a, e)$
has as aspect an aspect, which has as `cod` a type." The checkmark declares them
equal, which is clause three and the test `imagesRespectCodomain`.

Clauses one and two get no such diagram, and this is not an oversight: "each
domain element has *exactly one* image" is a cardinality claim, and a
commutative diagram can only ever equate two composites. The most characteristic
thing about an aspect is the thing this notation cannot express — which is why
§2.2 states functionality in prose and §2.2.3 has to work around it.

== The tests

#excerpt("test expect {", none)

The two `is sat` tests are consistency checks: the first that the whole
arrangement is realisable at all, the second that aspects need not be injective
--- "two different men can point to the same height", §2.2.

The three `is unsat` tests each negate one clause of `functorial` and confirm no
instance survives. They are worth having as regression tests, since a weakened
predicate would show up here immediately. They are not, however, refutations of
the paper's invalid arrows, and the comments no longer claim they are. The model
holds no labels, so "a person has a child" and "a person has as inner child a
child" are the same object to it --- and §2.2.1 is explicit that the second one
is a valid aspect.

== What is deliberately absent

*Facts / path equivalences (§2.3).* Nothing here composes two paths, so the
sequence machinery is not earned. §4.1 makes the omission harmless rather than
merely convenient: an olog is "a presentation of a category by generators
(objects and arrows) and relations (path congruences)", so a fact-free olog
presents the free category on its graph, and a functor out of a free category is
determined by its action on generators. What the model checks is §4.2.2's *key
diagram* --- an instance of a graph --- which coincides with Definition 3.2.3
precisely when no facts are declared.

*Multiple instances.* One Forge instance is one olog together with one functor.
Quantifying over several functors on a shared schema needs an `Instance` sig,
which §4.2.2's satisfaction relation would require and this rung does not.

*The rules of good practice (Rules 2.1.1 and 2.2.1).* Numbered environments in
the paper rather than sections. They constrain the text on boxes and arrows, and
are conventions for the author rather than structure a solver can check.

== Running it

```sh
racket olog.frg          # or: frg check olog.frg
```

Exit code `0` when every test passes, `1` when one fails, so this is safe in a
check script. Solving takes about five milliseconds; the two seconds are Racket
startup. `option verbose 0` silences the per-test lines while still reporting
failures.
