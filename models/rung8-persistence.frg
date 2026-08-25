#lang forge

// Rung 8: persistence — which layers of a derived-data stack must be stored,
// and where the root of the system sits.
//
// The subject is a stack of data layers connected by arrows. Each arrow is
// either DETERMINISTIC (re-running it on the same input reproduces the same
// output: compilation, template rendering, JSON serialisation) or STOCHASTIC
// (re-running it produces something different but comparably valid: a language
// model extracting structured records from prose). A third kind of arrow is
// UNCERTIFIED: it is asserted to exist but cannot be re-run at all, because its
// domain is not representable. The arrow from a person's intent to the prose
// they wrote is of this kind.
//
// The concrete system being described is this repository. The chezmoi source
// directory, its templates and its data file are the store; the files in the
// user's home directory are the materialised view; `chezmoi apply` is the
// deterministic arrow; and editing a file in the home directory rather than in
// the source directory is exactly the unsound operation of theorem 4.
//
// Layers and arrows are reused from olog.frg: a layer is a Type and an arrow is
// an Aspect, so `functorial` already supplies the one property the instance
// level needs, namely that an arrow's action is a function. Nothing here
// declares a Fact or a Path; the tests bound both to zero, which makes
// olog.frg's `factsHold` and `pathAction` vacuous rather than wrong.
//
// Deliberately absent, and why the omissions are harmless:
//
//   * Time and versioning. States are compared pairwise, before and after a
//     single regeneration, rather than being indexed by a clock. Every theorem
//     below is about one step, and idempotence of a single step is what makes
//     the many-step statement follow by induction, which is an argument this
//     model does not need to carry internally.
//
//   * Partial regeneration, incremental builds and caching. A regeneration here
//     recomputes a whole layer. Caching is an optimisation that is *correct*
//     precisely when it agrees with full recomputation, so modelling only full
//     recomputation loses nothing about correctness.
//
//   * The content of the layers. A layer holds exactly one element per state.
//     Nothing below distinguishes "the view changed a little" from "the view
//     changed completely", and no theorem needs that distinction.
//
//   * Cost. Regenerating a view is treated as free. The entire practical case
//     for persisting a view is that recomputation is expensive, and that is an
//     engineering tradeoff, not a soundness question.
//
// MUTATION RESULTS. Every test declared `is unsat` below was checked for
// vacuity by weakening the single constraint it is supposed to depend on,
// re-running it in isolation, and confirming it became satisfiable. All eight
// flipped; none is vacuous.
//
//   rootPlacementForwardHolds            weaken detAcyclic to `some Layer`
//   rootPlacementBackwardHolds           `views` uses reflexive `*detStep`
//   bothReasonsImplyPersistence          `all ... implies Stochastic` to `some`
//   deterministicRegenerationIsIdempotent  drop determinismIsSemantic
//   editsToViewsDoNotSurvive             drop determinismIsSemantic
//   viewIsDeterminedBySource             `regenerates` fixes the codomain
//                                        content to `in Element` rather than
//                                        to the computed image
//   regressTerminates                    weaken certAcyclic to `some Layer`
//   everyCertifiedRootPersists           `views` uses reflexive `*detStep`
open "category.frg"
open "olog.frg"

// Tests are the whole point of this file, so there is nothing to look at in
// the visualiser; without this, Forge opens Sterling and waits on stdin when
// the run finishes, which looks like a hang.
option run_sterling off

// A layer of the stack. The alias exists so that the prose below can say
// "layer" where olog.frg says "type"; they are the same thing.
sig Layer extends Type {}

// An arrow between layers, carrying its own re-run. `rerun` is the arrow you
// get by executing the same procedure a second time on the same input: for a
// deterministic arrow it must have the same action, and that requirement is
// what `determinismIsSemantic` below states. An uncertified arrow is given a
// re-run only because the field is total; nothing constrains it and no theorem
// reads it.
// Renamed from the obvious `Arrow` because category.frg now owns that name: an
// arrow between layers is a generating arrow of the presented category, so
// `Generator` is the standard word for it.
abstract sig Generator extends Aspect {
  rerun: one Generator
}

sig Deterministic extends Generator {}
sig Stochastic    extends Generator {}
sig Uncertified   extends Generator {}

// The arrows whose behaviour can be vouched for. An uncertified arrow is
// outside this set by definition, and theorem 5 is about where that boundary
// falls.
fun certifiable: set Generator { Deterministic + Stochastic }

pred stack {
  Type = Layer
  // Every arrow runs between layers. `dom` and `cod` are inherited from
  // category.frg and so range over all objects; this is what confines them to
  // the types of this olog, and it is free wherever `instance` is asserted.
  pathsAreTypedArrows
  Aspect = Generator
  no Fact
  no Path
  // Re-running a procedure does not change what it consumes or what it
  // produces, only what it produces *this time*.
  all a: Generator | a.rerun.dom = a.dom and a.rerun.cod = a.cod
  all a: Deterministic | a.rerun in Deterministic
  all a: Stochastic    | a.rerun in Stochastic
  all a: Uncertified   | a.rerun = a
  // An arrow from a layer to itself is not part of this subject matter and
  // makes "reachable from" degenerate.
  no a: Generator | a.dom = a.cod
}

// The one-step reachability relation induced by the deterministic arrows,
// as a relation on layers. Everything about regenerability is a statement
// about the transitive closure `^detStep` of this relation.
fun detStep: Type -> Type {
  { l1: Type, l2: Type | some a: Deterministic | a.dom = l1 and a.cod = l2 }
}

// Likewise for the certifiable arrows, used only by theorem 5.
fun certStep: Type -> Type {
  { l1: Type, l2: Type | some a: certifiable | a.dom = l1 and a.cod = l2 }
}

// The deterministic layer graph has no cycles. This is not a law of the world;
// it is an assumption that theorem 1 turns out to require, and the whole point
// of stating it separately is that theorem 1 is false without it.
pred detAcyclic {
  no l: Layer | l in l.^detStep
}

// The certifiable layer graph has no cycles: the same assumption, one arrow
// class wider. Theorem 5 needs this to rule out an infinite regress.
pred certAcyclic {
  no l: Layer | l in l.^certStep
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

// Reason one for persisting a layer: nothing maps into it at all. It is
// primary data — a voice transcript, a hand-written note — and if it is lost it
// cannot be recovered by any means, plausible or otherwise.
pred isPrimary[l: Layer] {
  no a: Generator | a.cod = l
}

// Reason two: something does map into it, but every such arrow is stochastic.
// The layer can be *replaced* by re-running the extractor, which will produce a
// different and comparably valid set of records, but it cannot be *rebuilt*.
pred hasOnlyStochasticInput[l: Layer] {
  some a: Generator | a.cod = l
  all a: Generator | a.cod = l implies a in Stochastic
}

// A layer with no incoming deterministic arrow. This is the source of the
// deterministic reachability relation, and the candidate definition of "must
// persist" that theorem 1 will test against the reachability definition.
pred isDetRoot[l: Layer] {
  no a: Deterministic | a.cod = l
}

// The layers that some deterministic root reaches by a path of deterministic
// arrows. These are the materialised views: markdown, JSON Schema, SKILL.md,
// compiled artifacts, the files chezmoi writes into the home directory. Safe to
// delete, because a finite number of deterministic steps puts them back.
fun views: set Layer {
  { l: Layer | some r: Layer | isDetRoot[r] and l in r.^detStep }
}

// The complement: the store.
fun persisted: set Layer { Layer - views }

// ---------------------------------------------------------------------------
// States and regeneration
// ---------------------------------------------------------------------------

// A state assigns to each layer the element currently sitting there: the bytes
// on disk. Two states are compared before and after one regeneration.
sig State {
  content: set Type -> Element
}

pred statesWellFormed {
  all s: State | all l: Layer | {
    one l.(s.content)
    (l.(s.content)).isa = l
  }
}

// A layer is up to date with respect to an incoming arrow when what is stored
// there is what that arrow computes from what is stored at its domain. This is
// the fixpoint condition of a materialised view.
pred upToDate[s: State, a: Generator] {
  (a.cod).(s.content) = ((a.dom).(s.content)).(a.act)
}

// Regenerating the codomain of `a` from its domain. The action used is that of
// `a.rerun`, not of `a`, because regeneration means executing the procedure
// again rather than replaying a recording of it. For a deterministic arrow the
// two coincide, and that coincidence is the entire content of theorem 3.
pred regenerates[s1: State, s2: State, a: Generator] {
  (a.cod).(s2.content) = ((a.dom).(s1.content)).(a.rerun.act)
  all l: Layer - a.cod | l.(s2.content) = l.(s1.content)
}

// The link between the syntactic classification of arrows and the semantic
// property it names: a deterministic arrow re-runs to the same function. This
// is stated separately from `stack` because theorems 1, 2 and 5 are purely
// about the shape of the layer graph and never look at an element, whereas
// theorems 3 and 4 are entirely about elements.
pred determinismIsSemantic {
  all a: Deterministic | a.rerun.act = a.act
}

// The instance-level setting shared by theorems 3 and 4.
pred running {
  stack
  functorial
  statesWellFormed
  determinismIsSemantic
}

test expect {

  // -------------------------------------------------------------------------
  // Grounding: the three-layer stack of the subject actually exists.
  // -------------------------------------------------------------------------

  // Prose (primary), atoms (reached by a stochastic arrow), views (reached by a
  // deterministic arrow), plus the uncertified arrow from unrepresentable
  // intent into prose. The classification comes out as claimed: prose and atoms
  // are persisted, the view layer is not.
  threeLayerStackExists: {
    stack
    detAcyclic
    some intent, prose, atoms, view: Layer | {
      intent != prose and intent != atoms and intent != view
      prose  != atoms and prose  != view
      atoms  != view
      some u: Uncertified   | u.dom = intent and u.cod = prose
      some s: Stochastic    | s.dom = prose  and s.cod = atoms
      some d: Deterministic | d.dom = atoms  and d.cod = view
      isPrimary[intent]
      hasOnlyStochasticInput[atoms]
      prose in persisted
      atoms in persisted
      view  in views
    }
  } for exactly 4 Layer, 4 Type, 4 Object, 3 Generator, 3 Aspect, 3 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is sat

  // -------------------------------------------------------------------------
  // Theorem 1: the root placement theorem.
  //
  // Claim: a layer must persist if and only if it is not reachable from a
  // persisted layer by a path of deterministic arrows. `persisted` is defined
  // independently, as the complement of what the deterministic roots reach, so
  // the biconditional is a real claim about two definitions and not a tautology.
  // -------------------------------------------------------------------------

  // Left to right, under acyclicity: no persisted layer is reachable from a
  // persisted layer along deterministic arrows.
  rootPlacementForwardHolds: {
    stack
    detAcyclic
    some l: Layer | {
      l in persisted
      some p: Layer | p in persisted and l in p.^detStep
    }
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is unsat

  // Right to left, under acyclicity: every view is reachable from a persisted
  // layer, so nothing is classified as disposable that could not in fact be
  // rebuilt from the store.
  rootPlacementBackwardHolds: {
    stack
    detAcyclic
    some l: Layer | {
      l in views
      no p: Layer | p in persisted and l in p.^detStep
    }
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is unsat

  // AND HERE IS THE REFUTATION. Drop acyclicity and the forward direction
  // fails. A cycle of deterministic arrows has no deterministic root, so no
  // layer in it is reachable from any root, so every layer in it is classified
  // as persisted — and yet each one is reachable from another persisted layer
  // by a deterministic path. The biconditional as stated is FALSE in general.
  //
  // The failure is not an artefact. A cycle of deterministic arrows is a set of
  // mutually derivable layers with no primary member, and the informal rule
  // "persist what cannot be regenerated" genuinely gives no answer there: any
  // one of them may be chosen as the store and the rest regenerated, but one of
  // them must be chosen, and reachability alone does not choose. Acyclicity is
  // the hypothesis under which the rule is well defined.
  rootPlacementFailsOnDeterministicCycles: {
    stack
    some l: Layer | {
      l in persisted
      some p: Layer | p in persisted and l in p.^detStep
    }
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is sat

  // -------------------------------------------------------------------------
  // Theorem 2: two reasons for persistence, not one.
  // -------------------------------------------------------------------------

  // Prose: primary, and not a layer fed by a stochastic arrow.
  primaryWithoutStochasticInput: {
    stack
    detAcyclic
    some l: Layer | isPrimary[l] and not hasOnlyStochasticInput[l]
  } for 4 Layer, 4 Type, 4 Object, 4 Generator, 4 Aspect, 4 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is sat

  // Atoms: fed only by stochastic arrows, and not primary. Together with the
  // previous test this shows the two conditions are independent rather than one
  // condition stated twice.
  stochasticInputWithoutBeingPrimary: {
    stack
    detAcyclic
    some l: Layer | hasOnlyStochasticInput[l] and not isPrimary[l]
  } for 4 Layer, 4 Type, 4 Object, 4 Generator, 4 Aspect, 4 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is sat

  // Both reasons are genuinely reasons: a layer satisfying either one is never
  // classified as a view. This is what makes the two conditions sufficient
  // rather than merely suggestive.
  bothReasonsImplyPersistence: {
    stack
    detAcyclic
    some l: Layer | (isPrimary[l] or hasOnlyStochasticInput[l]) and l in views
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is unsat

  // The converse fails, and it is worth recording that it does: a layer may be
  // persisted without satisfying either reason, namely a layer fed by a mixture
  // of a stochastic and an uncertified arrow, or one sitting in a deterministic
  // cycle. The two reasons are sufficient, not necessary.
  persistenceHasOtherCauses: {
    stack
    detAcyclic
    some l: Layer | l in persisted and not isPrimary[l] and not hasOnlyStochasticInput[l]
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is sat

  // -------------------------------------------------------------------------
  // Theorem 3: a deterministic arrow may be safely re-run.
  // -------------------------------------------------------------------------

  // Regenerating an up-to-date view across a deterministic arrow is the
  // identity on states: the fixpoint is a fixpoint. A view therefore cannot
  // drift from its source, and `chezmoi apply` on a clean tree is a no-op.
  deterministicRegenerationIsIdempotent: {
    running
    some s1, s2: State | some a: Deterministic | {
      upToDate[s1, a]
      regenerates[s1, s2, a]
      s2.content != s1.content
    }
  } for 4 Element, 3 Type, 3 Object, 3 Layer, 3 Generator, 3 Aspect, 3 Arrow, 2 State, 0 Path, 0 Fact is unsat

  // The contrast. Re-running a stochastic arrow on unchanged input changes what
  // is stored, so the layer it feeds has no fixpoint to return to and
  // "regenerate on demand" is simply unavailable there. This is the reason
  // atoms must be persisted even though an arrow does map into them.
  stochasticRegenerationDrifts: {
    running
    some s1, s2: State | some a: Stochastic | {
      upToDate[s1, a]
      regenerates[s1, s2, a]
      s2.content != s1.content
    }
  } for 4 Element, 3 Type, 3 Object, 3 Layer, 3 Generator, 3 Aspect, 3 Arrow, 2 State, 0 Path, 0 Fact is sat

  // -------------------------------------------------------------------------
  // Theorem 4: editing a materialised view is unsound.
  // -------------------------------------------------------------------------

  // The failure this prevents is real and reachable: a state in which the view
  // layer holds something other than what its deterministic source computes.
  // That is what a human editing a generated file produces.
  aViewCanBeEdited: {
    running
    some s1: State | some a: Deterministic | not upToDate[s1, a]
  } for 4 Element, 3 Type, 3 Object, 3 Layer, 3 Generator, 3 Aspect, 3 Arrow, 1 State, 0 Path, 0 Fact is sat

  // And it cannot survive. If the view has been edited away from its computed
  // value, the next regeneration necessarily changes it back; there is no
  // edited state that regeneration leaves alone. An edit to a view therefore
  // carries no information: the source determines the view entirely, and the
  // only durable way to change a generated file is to change what generates it.
  editsToViewsDoNotSurvive: {
    running
    some s1, s2: State | some a: Deterministic | {
      not upToDate[s1, a]
      regenerates[s1, s2, a]
      (a.cod).(s2.content) = (a.cod).(s1.content)
    }
  } for 4 Element, 3 Type, 3 Object, 3 Layer, 3 Generator, 3 Aspect, 3 Arrow, 2 State, 0 Path, 0 Fact is unsat

  // The stronger reading of "a view carries no information not present in its
  // source": two states that agree on the source layer, once regenerated, agree
  // on the view layer, whatever was in the view beforehand. Regeneration is a
  // function of the source alone.
  viewIsDeterminedBySource: {
    running
    some s1, s2, t1, t2: State | some a: Deterministic | {
      (a.dom).(s1.content) = (a.dom).(t1.content)
      regenerates[s1, s2, a]
      regenerates[t1, t2, a]
      (a.cod).(s2.content) != (a.cod).(t2.content)
    }
  } for 4 Element, 3 Type, 3 Object, 3 Layer, 3 Generator, 3 Aspect, 3 Arrow, 4 State, 0 Path, 0 Fact is unsat

  // -------------------------------------------------------------------------
  // Theorem 5: the regress terminates, but the root is not unique.
  // -------------------------------------------------------------------------

  // Prose is a projection of intent, and the arrow from intent to prose cannot
  // be certified. The regress therefore has to stop somewhere: in a finite
  // acyclic certifiable graph, some layer has no incoming certifiable arrow,
  // and that layer is the root of the store. There is no model in which every
  // layer can be rebuilt from a lower one.
  regressTerminates: {
    stack
    certAcyclic
    some Layer
    all l: Layer | some a: certifiable | a.cod = l
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is unsat

  // Without acyclicity the regress does not terminate: a cycle of certifiable
  // arrows gives every layer an incoming certifiable arrow and no root at all.
  // This is the same pathology as the theorem 1 refutation, seen from below.
  regressDoesNotTerminateInACycle: {
    stack
    some Layer
    all l: Layer | some a: certifiable | a.cod = l
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is sat

  // AND HERE IS THE SECOND REFUTATION. "The lowest layer with a certifiable
  // incoming arrow" is not well defined, because the root need not be unique:
  // two layers may each have no incoming certifiable arrow. Two independent
  // voice transcripts, or a transcript and a hand-written note, are exactly
  // this. Uniqueness is an extra assumption — that the certifiable graph has a
  // single minimal element — and it is not forced by anything in the
  // architecture. What termination gives is a non-empty *set* of roots.
  certifiedRootIsNotUnique: {
    stack
    certAcyclic
    some disj l1, l2: Layer | {
      no a: certifiable | a.cod = l1
      no a: certifiable | a.cod = l2
    }
  } for 4 Layer, 4 Type, 4 Object, 4 Generator, 4 Aspect, 4 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is sat

  // What survives of theorem 5: the set of roots is non-empty and every root
  // must persist. That much is well defined, and it is what the store has to
  // contain.
  everyCertifiedRootPersists: {
    stack
    detAcyclic
    some l: Layer | (no a: certifiable | a.cod = l) and l in views
  } for 5 Layer, 5 Type, 5 Object, 5 Generator, 5 Aspect, 5 Arrow, 0 Element, 0 State, 0 Path, 0 Fact is unsat
}
