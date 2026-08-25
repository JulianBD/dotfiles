#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#set page(width: 16cm, height: auto, margin: 1.4cm)
#set text(size: 10pt)
#set par(justify: true)

= olog.frg

A Forge encoding of the olog, after Spivak & Kent, _Ologs: A Categorical
Framework for Knowledge Representation_ (arXiv:1102.1889).

An olog is a category whose objects are *types* (§2.1, boxes labelled with a
singular indefinite noun phrase) and whose arrows are *aspects* (§2.2, drawn
from a domain of definition to a set of result values). Definition 3.2.3 gives
the semantics we actually check: an *instance* of an olog is a functor to
$bold("Set")$ — a set for each type, a function for each aspect.

== What the model contains

#table(
  columns: (auto, 1fr),
  stroke: 0.4pt + luma(180),
  [`sig Type`], [A box. Carries no structure: its English label is not something
    this model can hold.],
  [`sig Aspect`], [An arrow, with `dom` and `cod` fixing its endpoints, and
    `act` giving its action on elements.],
  [`sig Element`], [An instance of a type (§3.1.1) — a documented example of the
    distinction the box names.],
  [`pred functorial`], [The functor law, stated elementwise. This is the entire
    content of "an aspect is a functional relationship".],
)

== The functor law as a commutative diagram

The third clause of `functorial` — that an image lands in the codomain — is a
path equivalence, so it can be drawn the way the paper draws facts (§2.3).
Take the type of pairs $(a, e)$ where $a$ is an aspect and $e$ is an element of
its domain. There are two ways to reach a type from such a pair, and the fact
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

Read the two paths aloud, as the paper instructs. Clockwise: "a pair $(a, e)$
yields, via `act`, an element, which is a type." Anticlockwise: "a pair
$(a, e)$ has as aspect an aspect, which has as `cod` a type." The checkmark
declares them equal — which is exactly the Forge test `imagesRespectCodomain`,
where the negation is `unsat`.

The domain clause is the same square with `act` replaced by the projection to
$e$ and `cod` replaced by `dom`.

== Why the invalid aspects are refutable

§2.2.1 offers two arrows that look like aspects but are not: "a person has a
child", and "a mechanical pencil uses a piece of lead". A person may have two children, or none. Because `functorial` demands
exactly one image for every element of the domain type, no instance can exhibit
either arrow, and Forge reports both corresponding tests as `unsat`. The rule is
mechanically enforced rather than merely advised.

== What is deliberately absent

*Facts / path equivalences (§2.3).* Modelling arbitrary declared equations needs
paths, hence sequences of composable aspects. Nothing in this rung composes two
paths, so the machinery is not yet earned. The diagram above is a fact about the
meta-model, written in prose and checked by a test, not a `Fact` sig. When facts
are needed, note that every example in the paper is a triangle or a square —
encoding those shapes directly is far cheaper than general paths.

*Multiple instances.* One Forge instance is one olog together with one functor.
Quantifying over several functors on a shared schema needs an `Instance` sig,
which §4 (communication between ologs) would require and this rung does not.

*The rules of good practice (§2.1.1, §2.2.1).* "Begin with 'a' or 'an'", "yield
an English sentence", "begin with a verb" — these constrain the text on boxes
and arrows. They are conventions for the author, not structure a solver can
check.

== Running it

```sh
racket olog.frg < /dev/null
```

The redirect matters: Forge opens the Sterling visualiser and waits on standard
input when it finishes, so without it the process appears to hang. Solving
itself takes about five milliseconds.
