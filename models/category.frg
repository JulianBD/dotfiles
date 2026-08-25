#lang forge

// A category, from the definition. This is the floor beneath every other model
// in this directory.
//
// olog.frg and the rungs above it all assume composition: they speak of paths,
// of functors, of natural transformations. None of them says what composition
// *is*. This file says it, and says nothing else. A category is a collection of
// objects, a collection of arrows each with a domain and a codomain, a partial
// binary operation on arrows defined exactly when they are composable, and a
// chosen arrow at each object -- subject to three laws: composition is typed,
// associative, and unital.
//
// Composition is modelled as a ternary relation on arrows rather than as a
// function, because that is the honest reading of the definition. `f -> g -> h`
// means "f then g equals h". Requiring the relation to be single-valued on
// composable pairs is then a *stated law* rather than something smuggled in by
// the choice of encoding, and dropping it is a legal mutation. Had composition
// been declared `one Arrow`, the law would have been unfalsifiable.
//
// Deliberately absent: functors, natural transformations, limits, monoidal
// structure. Those are the rungs above. Also absent: any labelling of objects
// or arrows with English text -- that is what an olog adds on top, and it is
// why an olog is a presentation *of* a category rather than a kind of category.

option run_sterling off

sig Object {}

sig Arrow {
  dom: one Object,
  cod: one Object
}

// The category's structure lives in one distinguished atom so that composition
// can be a genuine relation between arrows rather than a field on an arrow.
one sig Cat {
  compose: set Arrow -> Arrow -> Arrow,
  identity: set Object -> Arrow
}

// "f then g", read left to right. Empty when f and g are not composable.
fun seq[f: Arrow, g: Arrow]: set Arrow { g.(f.(Cat.compose)) }

fun id[o: Object]: set Arrow { o.(Cat.identity) }

// Composition is defined only on composable pairs: the codomain of the first
// must be the domain of the second.
pred composableOnly {
  all f, g, h: Arrow | (f -> g -> h in Cat.compose) implies f.cod = g.dom
}

// ...and on every composable pair it is defined, and single-valued. This is the
// law that makes composition a partial *function* rather than merely a relation.
pred compositionIsFunctional {
  all f, g: Arrow | f.cod = g.dom implies one seq[f, g]
}

// The composite spans the outer endpoints.
pred compositionIsTyped {
  all f, g, h: Arrow | (f -> g -> h in Cat.compose) implies
    (h.dom = f.dom and h.cod = g.cod)
}

// Each object carries a chosen endoarrow.
pred identitiesAreChosen {
  all o: Object | one id[o]
  all o: Object | (id[o]).dom = o and (id[o]).cod = o
}

// The chosen arrows act as units on both sides.
pred unital {
  all f: Arrow | seq[id[f.dom], f] = f
  all f: Arrow | seq[f, id[f.cod]] = f
}

// Composing three composable arrows does not depend on the bracketing.
pred associative {
  all f, g, h: Arrow | (f.cod = g.dom and g.cod = h.dom) implies
    seq[seq[f, g], h] = seq[f, seq[g, h]]
}


// The same two laws, said the way the definition says them: composition is not
// an operation on arrows at large but a family of restrictions on homsets,
//
//     hom(A,B) x hom(B,C) --> hom(A,C)
//
// one map for each ordered triple of objects. `composableOnly` and
// `compositionIsTyped` are exactly this statement taken apart into a domain
// condition and a codomain condition; `homsetRestrictionAgrees` below checks
// that reading rather than asserting it.
fun hom[a: Object, b: Object]: set Arrow {
  { f: Arrow | f.dom = a and f.cod = b }
}

pred composesOnHomsets {
  // the pair is drawn from a composable pair of homsets...
  all f, g, h: Arrow | (f -> g -> h in Cat.compose) implies {
    some b: Object | f in hom[f.dom, b] and g in hom[b, g.cod]
  }
  // ...and the composite lands in the homset the restriction names.
  all f, g, h: Arrow | (f -> g -> h in Cat.compose) implies
    h in hom[f.dom, g.cod]
}

pred category {
  composableOnly
  compositionIsFunctional
  compositionIsTyped
  identitiesAreChosen
  unital
  associative
}

test expect {
  // Categories exist, with arrows that actually compose.
  categoryExists: {
    category
    some f, g: Arrow | f.cod = g.dom and f != g
  } for 6 Arrow, 3 Object is sat

  // A composable pair has exactly one composite. This is the content of
  // `compositionIsFunctional`, and the reason composition was encoded as a
  // relation: stated this way, the law can fail.
  compositesAreUnique: {
    category
    some f, g: Arrow | #seq[f, g] > 1
  } for 6 Arrow, 3 Object is unsat

  // Identities are not merely *chosen* but *determined*: any arrow acting as a
  // two-sided unit at an object is the chosen identity there. The proof the
  // solver is reconstructing is the one-liner e = e ; id = id.
  identityIsUnique: {
    category
    some o: Object | some i: Arrow | {
      i.dom = o
      i.cod = o
      all f: Arrow | f.dom = o implies seq[i, f] = f
      all f: Arrow | f.cod = o implies seq[f, i] = f
      i != id[o]
    }
  } for 6 Arrow, 3 Object is unsat

  // Associativity is not implied by the rest. Drop that one law and a
  // non-associative composition becomes available, so the law carries content.
  associativityIsIndependent: {
    composableOnly
    compositionIsFunctional
    compositionIsTyped
    identitiesAreChosen
    unital
    some f, g, h: Arrow | {
      f.cod = g.dom
      g.cod = h.dom
      seq[seq[f, g], h] != seq[f, seq[g, h]]
    }
  } for 8 Arrow, 3 Object is sat

  // The homset reading and the domain/codomain reading are the same condition.
  homsetRestrictionAgrees: {
    not ((composableOnly and compositionIsTyped) iff composesOnHomsets)
  } for 6 Arrow, 3 Object is unsat

  // Nor is unitality implied by the rest.
  unitalityIsIndependent: {
    composableOnly
    compositionIsFunctional
    compositionIsTyped
    identitiesAreChosen
    associative
    some f: Arrow | seq[id[f.dom], f] != f
  } for 8 Arrow, 3 Object is sat
}
