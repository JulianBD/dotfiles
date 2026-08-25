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
// isomorphism, since elements can always be tagged by type, and that tagging
// is the whole justification. It is *not* something §4.2.2 assumes: a key
// diagram sends each type to an arbitrary set, and the section's own extreme
// case — "for any set A ∈ |Set| a constant key diagram ∆(A) : G → |Set|
// satisfies any fact" — assigns the same set to every type, which `one Type`
// makes unrepresentable.
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

// §2.3 A fact: a declared equivalence between two paths. Definition 3.2.3's
// third bullet, previously vacuous here because nothing declared any facts.
//
// A path needs to be a *sequence* of composable aspects, so it is a linked
// list: `Id` is the empty path at a type, `Step` is one aspect followed by a
// shorter path. This is the least machinery that supports composites, and it
// is what a fact needs in order to say anything at all.
abstract sig Path {
  src: one Type,
  tgt: one Type,
  sends: set Element -> Element
}
sig Id extends Path {}
sig Step extends Path {
  head: one Aspect,
  tail: one Path
}

pred pathsWellFormed {
  all p: Id | p.src = p.tgt
  all p: Step | {
    p.head.dom = p.src         // the first arrow leaves the path's source
    p.head.cod = p.tail.src    // and lands where the rest of the path begins
    p.tail.tgt = p.tgt
  }
  all p: Step | p not in p.^tail   // a path is finite
}

// The action of a path is the composite of the actions of its aspects, with
// the empty path acting as the identity on its type.
pred pathAction {
  all p: Id | p.sends = { e1: Element, e2: Element | e1 = e2 and e1.isa = p.src }
  all p: Step | p.sends = (p.head.act) . (p.tail.sends)
}

sig Fact {
  lhs: one Path,
  rhs: one Path
}

pred factsWellFormed {
  all f: Fact | f.lhs.src = f.rhs.src and f.lhs.tgt = f.rhs.tgt
}

// Definition 3.2.3's third bullet: an instance must send the two paths of a
// declared fact to the *same* function.
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

// §4.1 A morphism of ologs, i.e. a functor between the categories they
// present. Since an olog presents a category by generators and relations, a
// functor out of it is determined by where the generators go — provided the
// declared facts are respected, which `preservesFacts` below is what checks.
//
// A morphism may in general send an aspect to a whole *path*; this sends
// aspects to single aspects, which is the special case the wire formats need.
sig Translation {
  onType:   set Type -> Type,
  onAspect: set Aspect -> Aspect,
  onPath:   set Path -> Path
}

pred translates[t: Translation, srcTypes: set Type, srcAspects: set Aspect, srcPaths: set Path] {
  // total and single-valued on the source olog
  all x: srcTypes   | one x.(t.onType)
  all a: srcAspects | one a.(t.onAspect)
  all p: srcPaths   | one p.(t.onPath)

  // arrows are carried to arrows spanning the carried endpoints
  all a: srcAspects | {
    (a.(t.onAspect)).dom = (a.dom).(t.onType)
    (a.(t.onAspect)).cod = (a.cod).(t.onType)
  }

  // paths are carried stepwise, so composites go to composites
  all p: srcPaths & Id | {
    p.(t.onPath) in Id
    (p.(t.onPath)).src = (p.src).(t.onType)
  }
  all p: srcPaths & Step | {
    p.(t.onPath) in Step
    (p.(t.onPath)).head = (p.head).(t.onAspect)
    (p.(t.onPath)).tail = (p.tail).(t.onPath)
  }
}

// A morphism must carry each declared fact to a fact that also holds in the
// target; otherwise it is only a graph morphism, not a functor.
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
  } for 6 Element, 4 Path is unsat

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
  } for 6 Element, 4 Path is sat
}
