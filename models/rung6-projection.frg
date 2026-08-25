#lang forge

// Rung 6: projection — Markdown as a natural transformation, not a source.
//
// The architecture under test. A store of atomic records is the persisted
// layer and the only thing anyone writes to. MyST Markdown is a *projection*
// of that store: regenerated on demand, never hand-edited. The claim to be
// checked is that "projection" here means what it means in category theory —
// a natural transformation between two instances over one and the same
// schema — and that the round trip is a section rather than an inverse.
//
// What the file does, in the vocabulary of Spivak & Kent. Definition 3.2.3
// asks an instance for a set per type and a function per aspect; olog.frg
// already supplies exactly that, via `isa` and `act`. The least additional
// machinery that yields *two* instances rather than one is to partition the
// elements into two worlds, the store world and the rendered world, and to
// require each aspect's action to stay inside the world it started in
// (`worldsAreClosed`). The restriction of `act` to each world is then an
// instance in its own right, and no second copy of `Aspect`, `Path` or `Fact`
// is needed. Both instances range over the same schema by construction,
// because there is only one schema in the model.
//
// A transformation is then a family of maps indexed by the types, which here
// is a single relation `render` constrained to preserve `isa` — its component
// at a type A is its restriction to the elements of A. Naturality is the
// commuting square: for every aspect f : A -> B, rendering and then following
// f agrees with following f and then rendering.
//
// The round trip. `parse` is a retraction for `render`: parse ∘ render is the
// identity on the store, so a record survives being rendered and read back.
// The converse composite render ∘ parse is *not* the identity — two byte
// sequences differing only in line wrapping parse to the same record — so
// `render` is a split monomorphism and not an isomorphism. That asymmetry is
// the formal content of "Markdown is a projection".
//
// Deliberately absent, and why it is harmless:
//
//   - Text. Nothing here models characters, headings, or MyST directives. A
//     rendered element is an opaque atom. Every property under test is a
//     property of the *maps*, not of the syntax, so the omission costs
//     nothing; the one place syntax would matter — that distinct formattings
//     collapse under parsing — is representable as non-injectivity of `parse`.
//
//   - Facts. This rung declares no path equivalences of its own, so the third
//     bullet of Definition 3.2.3 is again vacuous, exactly as in rung 0. The
//     one place a fact is doing work is `factsForceInjectivity` in olog.frg,
//     which this file cites rather than repeats.
//
//   - Time and regeneration order. Rendering is treated as a map, not as a
//     process. Rung 5 already carries precedence, and nothing about
//     naturality is temporal.
open "category.frg"
open "olog.frg"

// Without this Forge opens Sterling and blocks on stdin when a run finishes,
// which is indistinguishable from a hang. Everything in this file is a test.
option run_sterling off

// The two worlds. `StoreElement` carries the persisted atomic records;
// `RenderedElement` carries the Markdown projection of them. Both are
// elements of the same types, so both are instances over the same schema.
sig StoreElement extends Element {}
sig RenderedElement extends Element {}

// Every element belongs to exactly one world, and no aspect crosses between
// them. This is what makes `act` restrict to two separate instances rather
// than one mixed-up instance: the store's arrows land in the store, the
// rendered document's arrows land in the rendered document.
pred worldsAreClosed {
  Element = StoreElement + RenderedElement
  all a: Aspect | {
    (StoreElement.(a.act)) in StoreElement
    (RenderedElement.(a.act)) in RenderedElement
  }
}

// Two instances over one schema, in the sense of Definition 3.2.3.
pred twoInstances {
  instance
  worldsAreClosed
}

// A projection: the rendering map together with the parser that reads it
// back. `render` is the candidate natural transformation; `parse` is the
// candidate retraction.
sig Projection {
  render: set Element -> Element,
  parse:  set Element -> Element
}

// The typing discipline of a transformation. A natural transformation has one
// component per type, so the map must not move an element between types: the
// rendering of a record of type A is a rendered thing of type A. Totality and
// single-valuedness on the store make each component an honest function.
pred rendersTypewise[p: Projection] {
  all s: StoreElement | one s.(p.render)
  no RenderedElement.(p.render)
  all s: StoreElement | {
    s.(p.render) in RenderedElement
    (s.(p.render)).isa = s.isa
  }
}

pred parsesTypewise[p: Projection] {
  all r: RenderedElement | one r.(p.parse)
  no StoreElement.(p.parse)
  all r: RenderedElement | {
    r.(p.parse) in StoreElement
    (r.(p.parse)).isa = r.isa
  }
}

// THE COMMUTING SQUARE. For every aspect f : A -> B and every store record x
// of type A,
//
//       render(f(x))  =  f(render(x)).
//
// Read left to right along the top of the square: follow the aspect in the
// store, then render. Read down the left and along the bottom: render, then
// follow the same aspect in the rendered document. Naturality says the two
// routes agree. Concretely: the Markdown link from a rendered record to its
// parent points at the rendering of that record's parent, and not at some
// unrelated document.
pred natural[p: Projection] {
  all a: Aspect | all s: StoreElement | s.isa = a.dom implies
    (s.(a.act)).(p.render) = (s.(p.render)).(a.act)
}

// The section law: parse ∘ render = id on the store. A record survives being
// rendered and read back unchanged. This is the *only* direction that holds.
pred parseIsRetraction[p: Projection] {
  all s: StoreElement | (s.(p.render)).(p.parse) = s
}

// The failure of the other composite. render ∘ parse is not the identity on
// the rendered world: formatting is forgotten, so a document can parse to a
// record whose re-rendering is a different document. Asserting this witnesses
// that `render` is a split monomorphism and not an isomorphism.
pred renderIsNotSurjective[p: Projection] {
  some r: RenderedElement | (r.(p.parse)).(p.render) != r
}

pred projects[p: Projection] {
  twoInstances
  rendersTypewise[p]
  parsesTypewise[p]
}

// Reachability in the store from a chosen root, following any aspect any
// number of times. `Aspect.act` is the union of all the aspect actions.
fun reachableFrom[root: Element]: set univ {
  root.*(Aspect.act)
}

test expect {
  // The whole configuration is realisable: two instances over one schema, a
  // rendering that is natural, and a parser that retracts it.
  projectionExists: {
    some p: Projection | {
      projects[p]
      natural[p]
      parseIsRetraction[p]
      some StoreElement
      some Aspect
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 1 Projection is sat

  // Naturality has content — it is not implied by the typing discipline. A
  // type-correct, total, single-valued rendering that breaks the commuting
  // square exists. Without this test the unsat results below would prove
  // nothing, because a condition that everything satisfies constrains
  // nothing.
  naturalityIsNotAutomatic: {
    some p: Projection | {
      projects[p]
      not natural[p]
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 1 Projection is sat

  // ...and the specific shape of the failure: an aspect f and a record x for
  // which rendering after f differs from f after rendering. This is the
  // broken square exhibited directly rather than as a negation.
  brokenSquareExists: {
    some p: Projection | {
      projects[p]
      some a: Aspect | some s: StoreElement | {
        s.isa = a.dom
        (s.(a.act)).(p.render) != (s.(p.render)).(a.act)
      }
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 1 Projection is sat

  // A split monomorphism is injective. olog.frg proves this once, in
  // `factsForceInjectivity`, from the fact machinery of §2.3; this is that
  // result instantiated at render/parse. The argument is unchanged: if
  // render(x) = render(y) then applying the retraction to both sides gives
  // x = parse(render(x)) = parse(render(y)) = y. Architecturally: no two
  // distinct store records can render to the same Markdown, so the projection
  // never silently merges records.
  renderIsInjective: {
    some p: Projection | {
      projects[p]
      parseIsRetraction[p]
      some disj s1, s2: StoreElement | s1.(p.render) = s2.(p.render)
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 1 Projection is unsat

  // The retraction is what forbids the collapse, and nothing else does. Drop
  // it and two records may share a rendering — which is precisely the bug the
  // section law rules out.
  collapseWithoutRetraction: {
    some p: Projection | {
      projects[p]
      some disj s1, s2: StoreElement | s1.(p.render) = s2.(p.render)
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 1 Projection is sat

  // `parse`, by contrast, may and does collapse: two documents differing only
  // in formatting read back to the same record. So render ∘ parse is not the
  // identity, and `render` is a split monomorphism rather than an
  // isomorphism.
  parseIsNotInjective: {
    some p: Projection | {
      projects[p]
      parseIsRetraction[p]
      renderIsNotSurjective[p]
      some disj r1, r2: RenderedElement | r1.(p.parse) = r2.(p.parse)
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 1 Projection is sat

  // RECOMPUTABILITY, and the correction to it.
  //
  // The tempting claim is that naturality alone pins the projection down: two
  // renderings of the same store that are both natural must agree. That claim
  // is FALSE, and this satisfiable test is the counterexample. Naturality is
  // stable under relabelling the rendered world — post-composing a natural
  // transformation with an automorphism of the target instance leaves it
  // natural — so two natural renderings can disagree everywhere. Nothing in
  // the commuting square names any particular document.
  naturalityAloneDoesNotDetermineTheProjection: {
    some disj p, q: Projection | {
      projects[p]
      projects[q]
      natural[p]
      natural[q]
      some s: StoreElement | s.(p.render) != s.(q.render)
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 2 Projection is sat

  // What *is* true is the rooted form, which is why the hypothesis mentions a
  // chosen root. Fix a store record and require both renderings to agree
  // there; then they agree at every record reachable from it by following
  // aspects. Naturality propagates the choice along every arrow, so the
  // projection is recomputable from the store plus one anchoring decision per
  // connected component. Regeneration is deterministic given stable
  // identifiers, not given naturality alone.
  naturalityDeterminesTheProjectionFromARoot: {
    some p, q: Projection | some root: StoreElement | {
      projects[p]
      projects[q]
      natural[p]
      natural[q]
      root.(p.render) = root.(q.render)
      some s: StoreElement | {
        s in reachableFrom[root]
        s.(p.render) != s.(q.render)
      }
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 2 Projection is unsat

  // ...and not vacuously: two renderings agreeing at a root, with something
  // else actually reachable from it, do exist in these bounds.
  rootedAgreementIsRealisable: {
    some p, q: Projection | some root: StoreElement | {
      projects[p]
      projects[q]
      natural[p]
      natural[q]
      root.(p.render) = root.(q.render)
      some s: StoreElement | s != root and s in reachableFrom[root]
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 2 Projection is sat

  // Unreachable records are exactly where the rooted theorem stops. Two
  // natural renderings agreeing at a root may still disagree about a record
  // that no chain of aspects connects to it. This is the sharp boundary of
  // the previous theorem, and the practical reason a store needs one stable
  // identifier per component rather than one per store.
  disagreementSurvivesOffTheRootComponent: {
    some disj p, q: Projection | some root: StoreElement | {
      projects[p]
      projects[q]
      natural[p]
      natural[q]
      root.(p.render) = root.(q.render)
      some s: StoreElement | {
        s not in reachableFrom[root]
        s.(p.render) != s.(q.render)
      }
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 2 Projection is sat

  // Markdown is never the source of truth: no aspect crosses from the
  // rendered world back into the store. Editing a document therefore cannot
  // be reached by following store structure, which is the structural version
  // of "regenerated on demand, never edited directly".
  noAspectLeadsFromRenderedBackToStore: {
    twoInstances
    some a: Aspect | some r: RenderedElement | {
      some r.(a.act)
      r.(a.act) in StoreElement
    }
  } for 8 Element, 2 Type, 2 Aspect, 2 Path, 0 Fact, 1 Projection is unsat
}

// Mutation testing record. Every test above declared `is unsat` was checked
// for vacuity by weakening the one constraint it is supposed to depend on and
// confirming that it flips to satisfiable. A test that stays unsat under such
// a weakening is asserting nothing.
//
//   renderIsInjective — removed `parseIsRetraction[p]` from the test body.
//     Flipped to sat: without the section law, two distinct records may share
//     a rendering. The test depends on the retraction and on nothing else.
//
//   naturalityDeterminesTheProjectionFromARoot — removed `natural[q]`,
//     leaving only `natural[p]`. Flipped to sat: one natural rendering and
//     one arbitrary one may agree at the root and diverge downstream. The
//     test depends on naturality of both, which is what makes it a statement
//     about the commuting square rather than about the root alone.
//
//   noAspectLeadsFromRenderedBackToStore — deleted the two closure
//     conjuncts from `worldsAreClosed`, leaving the partition. Flipped to
//     sat: with the worlds no longer closed under `act`, an aspect can lead
//     out of the rendered document and back into the store. The test depends
//     on world closure and not on the partition.
