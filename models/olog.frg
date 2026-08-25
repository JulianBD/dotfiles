#lang forge

// An olog, after Spivak & Kent, "Ologs: A Categorical Framework for Knowledge
// Representation" (arXiv:1102.1889), presented on top of category.frg.
//
// §4.1 is the organising sentence: an olog is "a presentation of a category by
// generators (objects and arrows) and relations (path congruences)". This file
// now says that literally. A type *is* an object and an aspect *is* an arrow,
// in the sense of `extends`, so the vocabulary of category.frg — `dom`, `cod`,
// `Cat.compose`, `id`, `hom`, `seq` — is available here rather than being
// re-derived. A path is likewise an arrow: the arrow the presentation names as
// a composite of generators. A fact is an equation between two parallel
// arrows, which is what a relation of a presentation is.
//
// What survived the move to category.frg and why. `Path`, `Id` and `Step`
// remain, because rung 2, rung 4 and rung 9 all declare named path atoms
// (`one sig resultRoundTrip extends Step {}`) and read `head`, `tail` and
// `src` off them; removing the sigs would have rewritten those files rather
// than lifted them. What did *not* survive is the second definition of
// composition. Previously `Step` was a hand-rolled linked list and `pathAction`
// said, in effect, what composing two arrows does. Now `Step` is pinned to
// `Cat.compose` by the single equation `p = seq[p.head, p.tail]`, the old
// three clauses of `pathsWellFormed` about `head.dom`, `head.cod` and
// `tail.tgt` are *consequences* of `composableOnly` and `compositionIsTyped`
// rather than restatements of them, and the action of a path on elements is a
// consequence of one law saying that the action is functorial with respect to
// whatever `Cat.compose` relates.
//
// Deliberately absent: the whole of `category`. Only `composableOnly`,
// `compositionIsTyped` and single-valuedness are asserted here, never
// `compositionIsFunctional`, `unital` or `associative`. That is not an
// oversight, it is the difference between a presentation and the category it
// presents. A presentation carries a *partial* composition — exactly the
// composites it chooses to name — while the free category on the generators,
// modulo the relations, is closed under composition and is in general
// infinite. Rung 2's answer/answered-by pair already generates infinitely many
// formal composites before the facts collapse them, so demanding
// `compositionIsFunctional` in these scopes would demand that a finite model
// contain an infinite category. The omission is harmless because nothing above
// this file ever composes two arbitrary arrows; the rungs compose only along
// paths they have named, and those are exactly the composites that are pinned.
//
// Also absent, as before: the rules of good practice (Rules 2.1.1 and 2.2.1),
// which constrain the English text on boxes and arrows rather than the
// structure.

// `open` must be the first statement in the file, ahead of any option.
open "category.frg"

// Tests are the whole point of this file, so there is nothing to look at in
// the visualiser; without this, Forge opens Sterling and waits on stdin when
// the run finishes, which looks like a hang.
option run_sterling off

// §2.1 A type: a box, labelled with a singular indefinite noun phrase; an
// object of the presented category.
sig Type extends Object {}

// §2.2 An aspect: an arrow from a type to a type, and a generating arrow of
// the presented category. `dom` and `cod` are inherited from `Arrow`. The
// paper is emphatic that an aspect is a *functional* relationship, not merely
// a relation; `act` below is where that is enforced.
sig Aspect extends Arrow {
  act: set Element -> Element
}

// §3.1.1 An instance of a type: a documented example of that distinction.
//
// `one Type` makes the extensions pairwise disjoint, which Definition 3.2.3
// does not require — there, I(x) and I(y) are arbitrary sets and may overlap,
// as `a woman is a person` invites. Disjointness costs nothing up to
// isomorphism, since elements can always be tagged by type, and that tagging
// is the whole justification. It is *not* something §4.2.2 assumes: a key
// diagram sends each type to an arbitrary set, and the section's own extreme
// case — "for any set A ∈ |Set| a constant key diagram ∆(A) : G → |Set|
// satisfies any fact" — assigns the same set to every type, which `one Type`
// makes unrepresentable.
sig Element {
  isa: one Type
}

// §2.3 A path: an arrow of the presented category, named as a composite of
// generators. `Id` is the chosen identity at a type and `Step` is one aspect
// followed by a shorter path. `src` and `tgt` are retained as the names the
// rungs above already use; `pathsAreTypedArrows` below makes them synonyms for
// the inherited `dom` and `cod` rather than independent data.
abstract sig Path extends Arrow {
  src: one Type,
  tgt: one Type,
  sends: set Element -> Element
}
sig Id extends Path {}
sig Step extends Path {
  head: one Aspect,
  tail: one Path
}

// The generators and the named composites all run between types. `Object` and
// `Arrow` are wider than `Type` and `Path`, because category.frg admits
// categories that no olog presents, so this has to be said.
pred pathsAreTypedArrows {
  all f: Aspect + Path | f.dom in Type and f.cod in Type
  all p: Path | p.src = p.dom and p.tgt = p.cod
}

// The part of `category` that a presentation can carry: composition is defined
// only on composable pairs, it spans the outer endpoints, and it is
// single-valued where it is defined. `compositionIsFunctional` is deliberately
// weakened to `lone`, since a presentation names some composites and not
// others; see the header.
pred compositionIsPartiallyFunctional {
  all f, g: Arrow | lone seq[f, g]
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

// A path is well formed when it is the arrow of the presented category that
// its shape names: an `Id` is the chosen identity at its type, and a `Step` is
// the composite of its head with its tail. Everything the old hand-rolled
// version stated about endpoints now follows from category.frg's typing laws.
pred pathsWellFormed {
  composableOnly
  compositionIsTyped
  compositionIsPartiallyFunctional
  pathsAreTypedArrows

  // The presentation chooses an identity at each type it names one for. This
  // is `identitiesAreChosen` restricted to those types.
  all p: Id | {
    p = id[p.src]
    p.src = p.tgt
  }

  // The one equation that replaces the old linked-list semantics.
  all p: Step | p = seq[p.head, p.tail]

  // A path is finite.
  all p: Step | p not in p.^tail
}

// The action of an arrow on elements: `act` for a generator, `sends` for a
// named composite. Collecting the two into one relation is what lets the law
// below be stated once, over `Cat.compose`, instead of once per path shape.
fun action[f: Arrow]: set Element -> Element {
  (f & Aspect).act + (f & Path).sends
}

// An instance is a functor into Set, so it must carry composites to
// composites. Stated over `Cat.compose` directly, this is the general law; the
// old clause `p.sends = (p.head.act) . (p.tail.sends)` is now the instance of
// it at the tuple that `pathsWellFormed` pins for each `Step`.
pred pathAction {
  all p: Id | p.sends = { e1: Element, e2: Element | e1 = e2 and e1.isa = p.src }
  all f, g, h: Arrow | (f -> g -> h in Cat.compose) implies
    action[h] = (action[f]) . (action[g])
}

// §2.3 A fact: a relation of the presentation, i.e. an equation between two
// parallel arrows of the presented category.
sig Fact {
  lhs: one Path,
  rhs: one Path
}

pred factsWellFormed {
  all f: Fact | f.lhs.src = f.rhs.src and f.lhs.tgt = f.rhs.tgt
}

// Definition 3.2.3's third bullet: an instance must send the two arrows of a
// declared equation to the *same* function.
pred factsHold {
  all f: Fact | f.lhs.sends = f.rhs.sends
}

// A full instance, in the sense of Definition 3.2.3: a set per type, a
// function per aspect, and an equality of composites per declared fact.
pred instance {
  functorial
  pathsWellFormed
  pathAction
  factsWellFormed
  factsHold
}

// §4.1 A morphism of ologs is a functor between the presented categories.
//
// A functor F : C -> D is an object map together with, for each ordered pair
// of objects (A, B), a map hom_C(A, B) -> hom_D(F A, F B), preserving
// identities and composition. `onType` is the object map; `onAspect` and
// `onPath` together are the arrow map, split only because generators and named
// composites are different sigs here. `onArrow` reassembles them.
//
// A morphism may in general send an aspect to a whole *path*; this sends
// aspects to single aspects, which is the special case the wire formats need.
sig Translation {
  onType:   set Type -> Type,
  onAspect: set Aspect -> Aspect,
  onPath:   set Path -> Path
}

fun onArrow[t: Translation]: set Arrow -> Arrow { t.onAspect + t.onPath }

// The homset condition, written the way category.frg writes composition: not
// as a side condition on `dom` and `cod` but as a family of restrictions
//
//     hom_C(A, B) --> hom_D(F A, F B)
//
// one for each ordered pair of objects. Quantifying (A, B) over every type
// rather than only the source olog's types is what makes this equivalent to
// the pointwise reading: each arrow with typed endpoints lies in exactly one
// homset, so every arrow of `srcArrows` is covered exactly once.
// `homsetReadingAgrees` below checks that equivalence rather than assuming it.
pred preservesHomsets[t: Translation, srcArrows: set Arrow] {
  all a, b: Type | all f: srcArrows & hom[a, b] |
    f.(onArrow[t]) in hom[a.(t.onType), b.(t.onType)]
}

pred translates[t: Translation, srcTypes: set Type, srcAspects: set Aspect, srcPaths: set Path] {
  // The object map and the arrow map are total and single-valued on the
  // source olog. Totality per homset is what "a map hom -> hom" asks for.
  all x: srcTypes   | one x.(t.onType)
  all a: srcAspects | one a.(t.onAspect)
  all p: srcPaths   | one p.(t.onPath)

  // ...and the arrow map restricts to the homsets, as above.
  preservesHomsets[t, srcAspects + srcPaths]

  // F(id_A) = id_{F A}.
  all p: srcPaths & Id | {
    p.(t.onPath) in Id
    (p.(t.onPath)).src = (p.src).(t.onType)
  }

  // F(g . f) = F g . F f, read off the generators of each named composite.
  all p: srcPaths & Step | {
    p.(t.onPath) in Step
    (p.(t.onPath)).head = (p.head).(t.onAspect)
    (p.(t.onPath)).tail = (p.tail).(t.onPath)
  }
}

// A morphism must carry each declared equation to an equation that also holds
// in the target; otherwise it is only a morphism of the underlying graphs, not
// a functor between the presented categories.
pred preservesFacts[t: Translation, srcFacts: set Fact] {
  all eq: srcFacts | some img: Fact | {
    img.lhs = (eq.lhs).(t.onPath)
    img.rhs = (eq.rhs).(t.onPath)
  }
}

// Where a morphism lands. `translates` alone does not confine the image, so
// this is what says "into that olog and no other".
pred mapsInto[t: Translation, srcTypes: set Type, srcAspects: set Aspect,
              tgtTypes: set Type, tgtAspects: set Aspect] {
  all x: srcTypes   | x.(t.onType)   in tgtTypes
  all a: srcAspects | a.(t.onAspect) in tgtAspects
}

// The pointwise reading of the homset condition, kept only so that
// `homsetReadingAgrees` has something to compare against.
pred preservesEndpoints[t: Translation, srcArrows: set Arrow] {
  all f: srcArrows | {
    (f.(onArrow[t])).dom = (f.dom).(t.onType)
    (f.(onArrow[t])).cod = (f.cod).(t.onType)
  }
}

test expect {
  // An olog with instance data exists.
  instancesExist: {
    functorial
    some Aspect
    some Element
  } for 4 Object, 4 Arrow is sat

  // Two different elements may share an image: many men, one height (§2.2).
  aspectsNeedNotBeInjective: {
    functorial
    some disj e1, e2: Element | some a: Aspect |
      e1.(a.act) = e2.(a.act) and some e1.(a.act)
  } for 4 Object, 4 Arrow is sat

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
  } for 4 Object, 4 Arrow is unsat

  // The other half of functionality: nor may a domain element have *no* image.
  // "A person has a child" fails here too, for the childless.
  noDomainElementIsUnmapped: {
    functorial
    some a: Aspect | some e: Element |
      e.isa = a.dom and no e.(a.act)
  } for 4 Object, 4 Arrow is unsat

  // Typing is respected: an aspect cannot land outside its codomain.
  imagesRespectCodomain: {
    functorial
    some a: Aspect | some e, img: Element |
      img in e.(a.act) and img.isa != a.cod
  } for 4 Object, 4 Arrow is unsat

  // A named composite really is the composite that category.frg's composition
  // gives. This is the equation that replaced the linked list, so it deserves
  // a test of its own: a `Step` cannot fail to be `seq[head, tail]`.
  stepsAreComposites: {
    pathsWellFormed
    some p: Step | p != seq[p.head, p.tail]
  } for 4 Object, 8 Arrow, 4 Type, 4 Aspect, 4 Path is unsat

  // ...and the old endpoint clauses are now theorems rather than axioms. If a
  // step is the composite of its head and its tail, its head must leave the
  // step's source and land where the tail begins.
  endpointsFollowFromComposition: {
    pathsWellFormed
    some p: Step | {
      p.head.dom != p.src or p.head.cod != p.tail.src or p.tail.tgt != p.tgt
    }
  } for 4 Object, 8 Arrow, 4 Type, 4 Aspect, 4 Path is unsat

  // The action of a path is likewise a theorem now: it falls out of the one
  // law that the action is functorial over `Cat.compose`.
  pathActionFollowsFromComposition: {
    pathsWellFormed
    pathAction
    some p: Step | p.sends != (p.head.act) . (p.tail.sends)
  } for 4 Object, 8 Arrow, 4 Type, 4 Aspect, 4 Path, 4 Element is unsat

  // Steps and identities exist and compose, so the two unsat tests above are
  // not vacuous for want of a `Step` to quantify over.
  stepsExist: {
    instance
    some p: Step | some p.head and p.tail in Id
  } for 4 Object, 8 Arrow, 4 Type, 4 Aspect, 4 Path, 4 Element is sat

  // The homset reading of functoriality and the pointwise `dom`/`cod` reading
  // are the same condition, given a single-valued object map. This is the
  // olog-level counterpart of category.frg's `homsetRestrictionAgrees`.
  homsetReadingAgrees: {
    pathsAreTypedArrows
    some t: Translation | {
      all x: Type | one x.(t.onType)
      all f: Aspect + Path | one f.(onArrow[t])
      not (preservesHomsets[t, Aspect + Path] iff preservesEndpoints[t, Aspect + Path])
    }
  } for 4 Object, 6 Arrow, 4 Type, 3 Aspect, 3 Path, 1 Translation is unsat

  // A functor that fails to preserve identities is not admitted: an `Id` may
  // not be carried to a non-identity arrow.
  identitiesAreCarriedToIdentities: {
    pathsWellFormed
    some t: Translation | some p: Id |
      translates[t, Type, Aspect, Path] and p.(t.onPath) not in Id
  } for 4 Object, 8 Arrow, 4 Type, 3 Aspect, 4 Path, 1 Translation is unsat

  // Translations exist, so the test above is not vacuous.
  translationsExist: {
    pathsWellFormed
    some t: Translation | translates[t, Type, Aspect, Path] and some Id
  } for 4 Object, 8 Arrow, 4 Type, 3 Aspect, 4 Path, 1 Translation is sat

  // Facts have content. If a fact declares that `f` followed by some path is
  // the identity on f's domain, then f cannot collapse two elements: a split
  // monomorphism is injective. Nothing outside `factsHold` forces this, so
  // this test is what shows the third bullet of Definition 3.2.3 is now
  // carrying weight rather than being satisfied vacuously.
  factsForceInjectivity: {
    instance
    some f: Aspect, p: Path, eq: Fact | {
      eq.lhs in Step
      eq.lhs.head = f
      eq.lhs.tail = p
      eq.rhs in Id
      eq.rhs.src = f.dom
      some disj e1, e2: Element | {
        e1.isa = f.dom
        e2.isa = f.dom
        e1.(f.act) = e2.(f.act)
      }
    }
  } for 6 Element, 4 Path, 4 Object, 8 Arrow, 4 Type, 4 Aspect is unsat

  // ...and that unsat is not for want of room: the same shape minus the
  // collapsing pair is satisfiable in the same bounds.
  splitMonoExists: {
    instance
    some f: Aspect, p: Path, eq: Fact | {
      eq.lhs in Step
      eq.lhs.head = f
      eq.lhs.tail = p
      eq.rhs in Id
      eq.rhs.src = f.dom
      some e: Element | e.isa = f.dom
    }
  } for 6 Element, 4 Path, 4 Object, 8 Arrow, 4 Type, 4 Aspect is sat
}
