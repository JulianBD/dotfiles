#lang forge

// An olog, after Spivak & Kent, "Ologs: A Categorical Framework for Knowledge
// Representation" (arXiv:1102.1889).
//
// This rung encodes the schema level (§2.1 types, §2.2 aspects) together with
// the instance level (§3.2.3: an instance is a functor to Set — a set for each
// type, a function for each aspect).
//
// Deliberately absent: facts / path equivalences (§2.3). Those require paths,
// hence sequences of composable aspects, and nothing here needs to compose two
// paths yet. Also absent: the rules of good practice (§2.1.1, §2.2.1), which
// constrain the English text on boxes and arrows rather than the structure —
// "a type begins with 'a' or 'an'" is not a claim this model can carry.

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

  // §2.2.1, first invalid aspect: `a person has a child` is not an aspect,
  // because a person may have two children. No functorial instance can
  // exhibit a domain element with two images.
  noElementHasTwoImages: {
    functorial
    some a: Aspect | some e: Element | #(e.(a.act)) > 1
  } is unsat

  // §2.2.1, restated: nor may a domain element have *no* image. "A person has
  // a child" fails here too, for the childless.
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
