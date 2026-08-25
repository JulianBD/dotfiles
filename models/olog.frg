#lang forge

// An olog, after Spivak & Kent, "Ologs: A Categorical Framework for Knowledge
// Representation" (arXiv:1102.1889).
//
// This rung encodes the schema level (§2.1 types, §2.2 aspects) together with
// the instance level. Definition 3.2.3 asks an instance for three things: a set
// per type, a function per aspect, and an equality of composites for each
// declared fact. The third is vacuous here, because this rung declares no facts.
//
// Deliberately absent: facts / path equivalences (§2.3). Those require paths,
// hence sequences of composable aspects, and nothing here needs to compose two
// paths yet. §4.1 is what makes the omission harmless: an olog is "a
// presentation of a category by generators (objects and arrows) and relations
// (path congruences)", so a fact-free olog presents the free category on its
// graph, and a functor out of a free category is determined by its action on
// generators. `functorial` below therefore characterises functors, not merely
// graph morphisms.
//
// Also absent: the rules of good practice (Rules 2.1.1 and 2.2.1 — numbered
// environments, not sections), which constrain the English text on boxes and
// arrows rather than the structure. "A type begins with 'a' or 'an'" is not a
// claim this model can carry.

// Tests are the whole point of this file, so there is nothing to look at in
// the visualiser; without this, Forge opens Sterling and waits on stdin when
// the run finishes, which looks like a hang.
option run_sterling off

// §2.1 A type: a box, labelled with a singular indefinite noun phrase.
sig Type {}

// §2.2 An aspect: an arrow from a type to a type. The paper is emphatic that
// an aspect is a *functional* relationship, not merely a relation; `act` below
// is where that is enforced.
sig Aspect {
  dom: one Type,   // domain of definition
  cod: one Type,   // set of result values
  act: set Element -> Element
}

// §3.1.1 An instance of a type: a documented example of that distinction.
//
// `one Type` makes the extensions pairwise disjoint, which Definition 3.2.3
// does not require — there, I(x) and I(y) are arbitrary sets and may overlap,
// as `a woman is a person` invites. Disjointness costs nothing up to
// isomorphism, since elements can always be tagged by type, and it is what
// §4.2.2's key diagrams assume.
sig Element {
  isa: one Type
}

// §3.2.3 The functor law, stated elementwise.
//
// This is the whole content of "an aspect is functional": each element of the
// domain type has exactly one image, elements outside the domain have none,
// and every image lands in the codomain type.
pred functorial {
  all a: Aspect | {
    all e: Element | e.isa = a.dom implies one e.(a.act)
    all e: Element | e.isa != a.dom implies no e.(a.act)
    all e: Element | (a.act)[e].isa in a.cod
  }
}

test expect {
  // An olog with instance data exists.
  instancesExist: {
    functorial
    some Aspect
    some Element
  } is sat

  // Two different elements may share an image: many men, one height (§2.2).
  aspectsNeedNotBeInjective: {
    functorial
    some disj e1, e2: Element | some a: Aspect |
      e1.(a.act) = e2.(a.act) and some e1.(a.act)
  } is sat

  // The shape of §2.2.1's first invalid aspect, `a person has a child`: a
  // person may have two children. Note what this does and does not show. It
  // pins a consequence of `functorial` — no domain element has two images — and
  // would catch a future edit that weakened the predicate. It does not refute
  // that arrow, because the model holds no labels: §2.2.1 goes on to say the
  // arrow "may not be wrong but simply reflect that the author has a strange
  // world-view", and `has as inner child` is a perfectly valid aspect.
  noElementHasTwoImages: {
    functorial
    some a: Aspect | some e: Element | #(e.(a.act)) > 1
  } is unsat

  // The other half of functionality: nor may a domain element have *no* image.
  // "A person has a child" fails here too, for the childless.
  noDomainElementIsUnmapped: {
    functorial
    some a: Aspect | some e: Element |
      e.isa = a.dom and no e.(a.act)
  } is unsat

  // Typing is respected: an aspect cannot land outside its codomain.
  imagesRespectCodomain: {
    functorial
    some a: Aspect | some e, img: Element |
      img in e.(a.act) and img.isa != a.cod
  } is unsat
}
