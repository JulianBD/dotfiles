#lang forge

// Rung 9: capability as dependency, and planning as a partial functor.
//
// What is modelled. Two ologs. The first describes a pipeline one wants to
// run: its types are the artifacts that flow, its aspects are the stages that
// transform them. The second describes a harness: its types are the things the
// harness can hold, its aspects are the things it can do. A morphism from the
// first into the second is a plan. The pipeline is runnable on the harness
// exactly when such a morphism exists, is total, and is a functor rather than
// merely a graph morphism -- that is, when it also carries the pipeline's
// declared facts to facts the harness declares.
//
// The point of the rung is what happens when the morphism is only partial. A
// partial function has a domain of definition; the source types and aspects
// outside that domain are precisely the capabilities the harness is missing.
// So the build list is not a separate notion requiring separate machinery: it
// is the complement of the domain of definition, computed rather than
// declared. `missingTypes` and `missingAspects` below are functions, not sigs.
//
// The concrete grounding, run by hand: read source notes, compress each into a
// terse note, join the compressed pair, render the join back into human prose,
// and have the prose carry metadata identifying the note it came from. The
// capabilities that pipeline needs are a framed request over piped input, an
// independent per-session context, blinding (a node sees only what is piped to
// it and cannot read the filesystem), sequential composition, fan-out, a large
// output budget, a separate reasoning budget, and a response carrying both an
// artifact and metadata about it.
//
// Blinding is the interesting one and it is why facts, not just types and
// arrows, are load-bearing here. In the harness actually used, blinding was
// enforced by asking politely in prose; in a harness whose nodes have no tools
// it holds by construction. Both harnesses have the same inventory of types
// and arrows. They differ only in which equations they are prepared to
// declare. That difference is modelled below as the difference between system
// `PoliteHarness` and system `ToollessHarness`, which have identical types and
// aspects and differ only in whether the round-trip equation is declared. The
// pipeline is not runnable on the first and is runnable on the second, so a
// complete capability inventory does not imply a correct plan.
//
// Deliberately absent. First, quantitative capabilities -- output budget,
// reasoning budget, fan-out width. Those are numbers, not structure; a plan
// that fails on budget fails for reasons this model cannot see, and folding
// them in would add arithmetic without changing any theorem here. They are
// represented, where represented at all, by the presence or absence of the
// arrow that consumes them. Second, instance data: every test below runs with
// zero elements, because fact *preservation* (does the image of a declared
// equation appear among the target's declared equations) is a schema-level
// question, unlike fact *holding*, which is what olog.frg's `factsHold`
// checks. The omission is harmless because a plan is a claim about schemas;
// whether a particular harness run produces correct data is a different
// question, asked at a different rung.
//
// Third, and least harmless, so stated plainly: the morphisms here are neither
// full nor faithful. `preservesFacts` in olog.frg asks only that each declared
// source fact have an image among the target's declared facts. It does not ask
// that the target declare no *extra* equations between images. That asymmetry
// is exactly what makes Theorem 3 below come out true, and the comment on that
// test says so.
open "category.frg"
open "olog.frg"

// Without this Forge opens Sterling when a run finishes and waits on stdin,
// which looks like a hang. This file is tests only; there is nothing to view.
option run_sterling off

// ---------------------------------------------------------------------------
// The pipeline olog. Types are artifacts, aspects are stages.
// ---------------------------------------------------------------------------

one sig ASourceNote   extends Type {}  // a source note, as written
one sig ATerseNote    extends Type {}  // a terse note, the compression of one source note
one sig AJoinedNote   extends Type {}  // a joined note, the concatenation of the compressions
one sig AProseSummary extends Type {}  // a prose summary, human-readable, carrying its own provenance

one sig compresses extends Aspect {}  // a source note compresses to a terse note
one sig joins      extends Aspect {}  // a terse note joins into a joined note
one sig renders    extends Aspect {}  // a joined note renders as a prose summary
one sig provenance extends Aspect {}  // a prose summary has as provenance the source note it came from

// ---------------------------------------------------------------------------
// The system olog. Types are things a harness can hold, aspects are things it
// can do.
// ---------------------------------------------------------------------------

one sig APipedPayload      extends Type {}  // a piped payload: bytes on standard input
one sig ASessionOutput     extends Type {}  // a session output: what one independent, blinded session returned
one sig AnAnnotatedReply   extends Type {}  // an annotated reply: an artifact together with metadata about it

one sig framedRequest extends Aspect {}  // a piped payload has as result the output of a framed request over it
one sig collects      extends Aspect {}  // session outputs collect into a piped payload (fan-in, sequential composition)
one sig annotates     extends Aspect {}  // a piped payload has as annotated reply the artifact-plus-metadata built from it
one sig recovers      extends Aspect {}  // an annotated reply has as recovered payload the input its metadata names

// ---------------------------------------------------------------------------
// Paths, and the one declared fact on each side.
//
// The pipeline declares: compressing a source note, joining, rendering, and
// then following the provenance of the result returns the source note one
// started from. This is the equation that says the summary really does carry
// metadata about *its own* input rather than plausible-looking metadata. It is
// the formal content of blinding-plus-annotation: a node that could read the
// filesystem could satisfy the arrows while breaking the equation.
// ---------------------------------------------------------------------------

one sig SourceLoop  extends Id   {}  // the empty path at a source note
one sig ThenProv    extends Step {}  // provenance, then nothing
one sig ThenRender  extends Step {}  // renders, then the above
one sig ThenJoin    extends Step {}  // joins, then the above
one sig RoundTrip   extends Step {}  // compresses, then the above: the whole loop

one sig PayloadLoop extends Id   {}  // the empty path at a piped payload
one sig ThenRecover extends Step {}
one sig ThenAnnot   extends Step {}
one sig ThenCollect extends Step {}
one sig SysRoundTrip extends Step {}

one sig PipelineLoopIsIdentity extends Fact {}  // the pipeline's declared fact
one sig HarnessLoopIsIdentity  extends Fact {}  // the same equation, declared by a harness that can guarantee it

// ---------------------------------------------------------------------------
// A pipeline and a system, as bundles of the olog they present. Bundling lets
// the theorems quantify over systems in first-order form, which is what keeps
// them checkable.
// ---------------------------------------------------------------------------

sig Pipeline {
  needsTypes:   set Type,
  needsAspects: set Aspect,
  needsPaths:   set Path,
  needsFacts:   set Fact
}

sig System {
  provides: set Type,    // what the harness can hold
  performs: set Aspect,  // what the harness can do
  walks:    set Path,    // the composites available in it
  obeys:    set Fact     // the equations it is prepared to guarantee
}

one sig ThePipeline extends Pipeline {}

// Three harnesses, ordered by capability.
one sig LinearHarness   extends System {}  // framed requests only: no fan-in, no annotation
one sig PoliteHarness   extends System {}  // full inventory; blinding requested in prose, so no equation guaranteed
one sig ToollessHarness extends System {}  // full inventory; nodes have no tools, so the equation holds by construction

pred schema {
  Type = ASourceNote + ATerseNote + AJoinedNote + AProseSummary
       + APipedPayload + ASessionOutput + AnAnnotatedReply
  Aspect = compresses + joins + renders + provenance
         + framedRequest + collects + annotates + recovers
  Path = SourceLoop + ThenProv + ThenRender + ThenJoin + RoundTrip
       + PayloadLoop + ThenRecover + ThenAnnot + ThenCollect + SysRoundTrip
  Fact = PipelineLoopIsIdentity + HarnessLoopIsIdentity

  compresses.dom = ASourceNote   and compresses.cod = ATerseNote
  joins.dom      = ATerseNote    and joins.cod      = AJoinedNote
  renders.dom    = AJoinedNote   and renders.cod    = AProseSummary
  provenance.dom = AProseSummary and provenance.cod = ASourceNote

  framedRequest.dom = APipedPayload    and framedRequest.cod = ASessionOutput
  collects.dom      = ASessionOutput   and collects.cod      = APipedPayload
  annotates.dom     = APipedPayload    and annotates.cod     = AnAnnotatedReply
  recovers.dom      = AnAnnotatedReply and recovers.cod      = APipedPayload

  SourceLoop.src = ASourceNote and SourceLoop.tgt = ASourceNote
  ThenProv.head   = provenance and ThenProv.tail   = SourceLoop
  ThenRender.head = renders    and ThenRender.tail = ThenProv
  ThenJoin.head   = joins      and ThenJoin.tail   = ThenRender
  RoundTrip.head  = compresses and RoundTrip.tail  = ThenJoin

  PayloadLoop.src = APipedPayload and PayloadLoop.tgt = APipedPayload
  ThenRecover.head  = recovers      and ThenRecover.tail  = PayloadLoop
  ThenAnnot.head    = annotates     and ThenAnnot.tail    = ThenRecover
  ThenCollect.head  = collects      and ThenCollect.tail  = ThenAnnot
  SysRoundTrip.head = framedRequest and SysRoundTrip.tail = ThenCollect

  PipelineLoopIsIdentity.lhs = RoundTrip    and PipelineLoopIsIdentity.rhs = SourceLoop
  HarnessLoopIsIdentity.lhs  = SysRoundTrip and HarnessLoopIsIdentity.rhs  = PayloadLoop

  ThePipeline.needsTypes   = ASourceNote + ATerseNote + AJoinedNote + AProseSummary
  ThePipeline.needsAspects = compresses + joins + renders + provenance
  ThePipeline.needsPaths   = SourceLoop + ThenProv + ThenRender + ThenJoin + RoundTrip
  ThePipeline.needsFacts   = PipelineLoopIsIdentity

  LinearHarness.provides = APipedPayload + ASessionOutput
  LinearHarness.performs = framedRequest
  LinearHarness.walks    = PayloadLoop
  no LinearHarness.obeys

  PoliteHarness.provides = APipedPayload + ASessionOutput + AnAnnotatedReply
  PoliteHarness.performs = framedRequest + collects + annotates + recovers
  PoliteHarness.walks    = PayloadLoop + ThenRecover + ThenAnnot + ThenCollect + SysRoundTrip
  no PoliteHarness.obeys

  ToollessHarness.provides = PoliteHarness.provides
  ToollessHarness.performs = PoliteHarness.performs
  ToollessHarness.walks    = PoliteHarness.walks
  ToollessHarness.obeys    = HarnessLoopIsIdentity

  // The schema is well formed as an olog in the sense of olog.frg.
  pathsWellFormed
  factsWellFormed
}

// ---------------------------------------------------------------------------
// A partial translation.
//
// olog.frg's `translates` demands `one x.(t.onType)` for every source type: it
// is a total function on the source olog. The predicate below demands only
// `lone`, so it is a partial function, and the types on which it happens to be
// undefined are the whole subject of this file. Everything else -- that arrows
// are carried to arrows spanning the carried endpoints, that paths are carried
// stepwise -- is inherited unchanged, but guarded so that it constrains only
// the part of the source on which the translation is actually defined.
//
// Note the guard style. Writing `all a: srcAspects | (a.(t.onAspect)).dom =
// (a.dom).(t.onType)` without a guard would be satisfied vacuously in a way
// that is easy to misread: when the aspect has no image the left side is
// empty, so the equation would silently force the domain type to be undefined
// too. Guarding on `some a.(t.onAspect)` says what is meant, namely that where
// the translation is defined it behaves like a morphism.
// ---------------------------------------------------------------------------

pred partiallyTranslates[t: Translation, srcTypes: set Type, srcAspects: set Aspect, srcPaths: set Path] {
  // partial and single-valued
  all x: srcTypes   | lone x.(t.onType)
  all a: srcAspects | lone a.(t.onAspect)
  all p: srcPaths   | lone p.(t.onPath)

  // nothing outside the source olog is assigned an image, so that the domain
  // of definition below is a statement about this pipeline and not an artefact
  // of leftover tuples elsewhere in the universe
  (t.onType).Type     in srcTypes
  (t.onAspect).Aspect in srcAspects
  (t.onPath).Path     in srcPaths

  // where defined on an arrow, endpoints are carried along with it
  all a: srcAspects | some a.(t.onAspect) implies {
    (a.(t.onAspect)).dom = (a.dom).(t.onType)
    (a.(t.onAspect)).cod = (a.cod).(t.onType)
  }

  // where defined on a path, composites go to composites
  all p: srcPaths & Id | some p.(t.onPath) implies {
    p.(t.onPath) in Id
    (p.(t.onPath)).src = (p.src).(t.onType)
  }
  all p: srcPaths & Step | some p.(t.onPath) implies {
    p.(t.onPath) in Step
    (p.(t.onPath)).head = (p.head).(t.onAspect)
    (p.(t.onPath)).tail = (p.tail).(t.onPath)
  }
}

// The domain of definition of the partial function, and its complement within
// the source olog: the build list. These are computed, not declared.
fun definedTypes[t: Translation]:   set Type   { (t.onType).Type }
fun definedAspects[t: Translation]: set Aspect { (t.onAspect).Aspect }
fun definedPaths[t: Translation]:   set Path   { (t.onPath).Path }

fun missingTypes[t: Translation, p: Pipeline]:   set Type   { p.needsTypes   - definedTypes[t] }
fun missingAspects[t: Translation, p: Pipeline]: set Aspect { p.needsAspects - definedAspects[t] }
fun missingPaths[t: Translation, p: Pipeline]:   set Path   { p.needsPaths   - definedPaths[t] }

// Totality: the build list is empty.
pred total[t: Translation, p: Pipeline] {
  no missingTypes[t, p]
  no missingAspects[t, p]
  no missingPaths[t, p]
}

// A plan: a partial translation from the pipeline olog whose images, where
// defined, lie inside the system olog.
pred plan[t: Translation, p: Pipeline, s: System] {
  partiallyTranslates[t, p.needsTypes, p.needsAspects, p.needsPaths]
  mapsInto[t, p.needsTypes, p.needsAspects, s.provides, s.performs]
  definedPaths[t].(t.onPath) in s.walks
}

// olog.frg's `preservesFacts` says each declared source fact has *some* image
// among the Facts of the universe. A plan needs more: the image must be a fact
// the target system is prepared to guarantee.
pred preservesFactsInto[t: Translation, srcFacts: set Fact, s: System] {
  preservesFacts[t, srcFacts]
  all eq: srcFacts | some img: s.obeys | {
    img.lhs = (eq.lhs).(t.onPath)
    img.rhs = (eq.rhs).(t.onPath)
  }
}

// Runnability, in full: total, landing in the system, and a functor.
pred runnable[t: Translation, p: Pipeline, s: System] {
  plan[t, p, s]
  total[t, p]
  preservesFactsInto[t, p.needsFacts, s]
}

// Implementability of one system on another: the same notion, with a whole
// system olog as the source. This is what "port to a different provider"
// means.
pred implements[u: Translation, s: System, r: System] {
  partiallyTranslates[u, s.provides, s.performs, s.walks]
  mapsInto[u, s.provides, s.performs, r.provides, r.performs]
  definedPaths[u].(u.onPath) in r.walks
  all x: s.provides | some x.(u.onType)
  all a: s.performs | some a.(u.onAspect)
  all p: s.walks    | some p.(u.onPath)
  preservesFactsInto[u, s.obeys, r]
}

// Composition of translations, elementwise on the three carriers. Functor
// composition, written out.
pred composite[v: Translation, t: Translation, u: Translation] {
  v.onType   = (t.onType).(u.onType)
  v.onAspect = (t.onAspect).(u.onAspect)
  v.onPath   = (t.onPath).(u.onPath)
}

// ---------------------------------------------------------------------------

test expect {

  // ---- Theorem 1: totality plus fact preservation is exactly runnability. ---
  //
  // Direction one, the positive case. On the harness whose nodes have no
  // tools, a plan exists: the artifacts map onto payloads, session outputs and
  // annotated replies, the stages map onto framed requests, fan-in and
  // annotation, and the pipeline's round-trip equation lands on the equation
  // that harness declares.
  runnableOnToollessHarness: {
    schema
    some t: Translation | runnable[t, ThePipeline, ToollessHarness]
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is sat

  // Direction two, the negative case that is about missing capabilities rather
  // than about facts. The linear harness can issue framed requests and nothing
  // else; there is no fan-in, so `joins` and `provenance` have nowhere to go.
  // No plan onto it is runnable.
  notRunnableOnLinearHarness: {
    schema
    some t: Translation | runnable[t, ThePipeline, LinearHarness]
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is unsat

  // The build list is nonempty there, and it is computed rather than asserted:
  // every plan onto the linear harness leaves at least one pipeline aspect
  // without an image. This is the non-vacuity partner of the test above -- it
  // shows the failure is a missing image and not an absence of plans.
  linearHarnessHasNonemptyBuildList: {
    schema
    all t: Translation | plan[t, ThePipeline, LinearHarness]
      implies some missingAspects[t, ThePipeline]
    some t: Translation | plan[t, ThePipeline, LinearHarness]
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is sat

  // ---- Theorem 2: a complete inventory does not imply a correct plan. ------
  //
  // The polite harness has exactly the types and aspects of the toolless one.
  // A plan onto it can therefore be total: nothing is missing, the build list
  // is empty, every piece is in stock. It is still not a functor, because the
  // pipeline's round-trip equation has no image among the equations that
  // harness is prepared to guarantee -- blinding was requested in prose, not
  // enforced by construction. This is the practically useful consequence of
  // the whole model.
  totalYetNotRunnable: {
    schema
    some t: Translation | {
      plan[t, ThePipeline, PoliteHarness]
      total[t, ThePipeline]
      not preservesFactsInto[t, ThePipeline.needsFacts, PoliteHarness]
    }
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is sat

  // ...and no plan onto the polite harness is runnable, however the artifacts
  // are assigned. The gap is not a labelling accident.
  notRunnableOnPoliteHarness: {
    schema
    some t: Translation | runnable[t, ThePipeline, PoliteHarness]
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is unsat

  // ---- Theorem 3: monotonicity of the build list under capability addition. -
  //
  // If system r contains everything system s does, then every plan onto s is
  // already a plan onto r with the same domain of definition, so the build
  // list cannot grow. The witness that shows this is not vacuous is
  // `buildListStrictlyShrinks` below.
  //
  // Read the result carefully before believing it in a wider setting. This
  // comes out true because `preservesFactsInto` is existential in the target's
  // facts -- a target need only *have* the image equation -- and because
  // capability addition is modelled as a superset. A capability that must
  // itself preserve existing facts is still safe under those definitions: the
  // extra facts it brings can only make the existential easier. Monotonicity
  // would fail for a *faithful* plan, one required to reflect facts as well as
  // preserve them, since a new capability that forces two previously distinct
  // composites to agree would invalidate an existing plan. This model does not
  // demand faithfulness, and so it does not exhibit that failure; that is a
  // limit of the definition, not evidence that the risk is unreal.
  buildListNeverGrows: {
    schema
    some s, r: System | some t: Translation | {
      s.provides in r.provides
      s.performs in r.performs
      s.walks    in r.walks
      s.obeys    in r.obeys
      plan[t, ThePipeline, s]
      no u: Translation | {
        plan[u, ThePipeline, r]
        missingTypes[u, ThePipeline]   in missingTypes[t, ThePipeline]
        missingAspects[u, ThePipeline] in missingAspects[t, ThePipeline]
        missingPaths[u, ThePipeline]   in missingPaths[t, ThePipeline]
      }
    }
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is unsat

  // Non-vacuity for the above: the ordering it quantifies over is real, and the
  // build list genuinely does shrink from the linear harness to the polite one
  // rather than being empty or constant throughout.
  buildListStrictlyShrinks: {
    schema
    some t, u: Translation | {
      plan[t, ThePipeline, LinearHarness]
      plan[u, ThePipeline, PoliteHarness]
      some missingAspects[t, ThePipeline]
      no missingAspects[u, ThePipeline]
      no missingTypes[u, ThePipeline]
    }
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is sat

  // ---- Theorem 4: composition of plans. ------------------------------------
  //
  // If the pipeline is runnable on s, and s is implementable on r, then the
  // composite translation makes the pipeline runnable on r. This is functor
  // composition, and it is what licenses porting a pipeline to another
  // provider without re-deriving the plan.
  planComposition: {
    schema
    some s, r: System | some t, u: Translation | {
      runnable[t, ThePipeline, s]
      implements[u, s, r]
      no v: Translation | composite[v, t, u] and runnable[v, ThePipeline, r]
    }
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is unsat

  // Non-vacuity for composition: the hypotheses are jointly satisfiable, so
  // the test above is not unsat merely because nothing is ever runnable and
  // implementable at the same time.
  compositionHypothesesHold: {
    schema
    some s, r: System | some t, u: Translation | {
      runnable[t, ThePipeline, s]
      implements[u, s, r]
    }
  } for 0 Element, 7 Type, 8 Aspect, 10 Path, 2 Fact, 3 Translation, 1 Pipeline, 3 System is sat
}

// ---------------------------------------------------------------------------
// Mutation record. Every test declared `is unsat` was re-run with the specific
// constraint it depends on removed or weakened, to confirm it flips to sat and
// is therefore not vacuous. The file as committed is the unmutated version.
//
//   notRunnableOnLinearHarness
//     - give the linear harness the full inventory and the equation: sat.
//     - drop `mapsInto` and the `walks` confinement from `plan`, and grant the
//       equation: sat. (Dropping the confinement alone leaves it unsat,
//       because fact preservation still fails; the two failures are
//       independent, which is the content of Theorem 2.)
//   notRunnableOnPoliteHarness
//     - let the polite harness declare the equation: sat.
//     - drop `preservesFactsInto` from `runnable`: sat.
//   buildListNeverGrows
//     - drop all three of the `provides`/`performs`/`walks` orderings from the
//       hypothesis at once: sat. Dropping any one alone leaves it unsat,
//       because the remaining two still rule out the only pair of systems that
//       could witness growth. A single-clause mutation would have looked like
//       a vacuous test and is not.
//   planComposition
//     - compose the type maps in the wrong order: sat.
//     - drop `preservesFactsInto` from `implements`: sat.
//     - weakening `composite` to ignore the second translation on paths leaves
//       it unsat, since the quantifiers admit the case where the two systems
//       coincide; that mutation is simply not binding, not evidence of a
//       vacuous test.
// ---------------------------------------------------------------------------
