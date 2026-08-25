#lang forge

// Rung 2: the tool-call round trip, in both wire formats, and the functor
// between them.
//
// Written as an olog: every type and aspect below is an atom of `Type` and
// `Aspect` from olog.frg, so `instance` there polices this schema.
//
// The empirical claim this rung encodes was measured, not assumed. Across 240
// Claude Code session transcripts (48,446 records) there are 10,066 distinct
// tool_use ids and 10,066 distinct tool_result_ids, with zero calls lacking a
// result and zero results lacking a call. That perfect pairing is the fact
// declared below, and it is a path equivalence rather than a cardinality
// bound, which is why rung 1's fact-free meta-model could not state it.
open "olog.frg"

// ── The Anthropic olog ──────────────────────────────────────────────────────
// Results are carried by a *user* turn. There is no `tool` role: a tool_use is
// a content block in an assistant turn, a tool_result a content block in a
// user turn, and N results answering N calls share a single user turn.
one sig AnAssistantTurn extends Type {}   // an assistant turn
one sig AUserTurn       extends Type {}   // a user turn
one sig AToolCall       extends Type {}   // a tool call
one sig AToolResult     extends Type {}   // a tool result

one sig callIn     extends Aspect {}  // a tool call occurs in an assistant turn
one sig resultIn   extends Aspect {}  // a tool result occurs in a user turn
one sig answers    extends Aspect {}  // a tool result answers a tool call
one sig answeredBy extends Aspect {}  // a tool call is answered by a tool result

// ── The OpenAI olog (Responses API) ─────────────────────────────────────────
// Flat items. No turn groups a set of outputs, and there is no analogue of
// `resultIn` — that absence is the whole difference between the two formats.
one sig AFunctionCall       extends Type {}  // a function call
one sig AFunctionCallOutput extends Type {}  // a function call output

one sig outAnswers    extends Aspect {}  // an output answers a function call
one sig outAnsweredBy extends Aspect {}  // a function call is answered by an output

// ── Paths, so the round-trip facts can be stated ────────────────────────────
// Each side needs: an identity at each of its two paired types, and the two
// length-2 composites that the facts equate with those identities.
one sig idCall, idResult          extends Id {}
one sig pAnsweredBy, pAnswers     extends Step {}   // the length-1 tails
one sig resultRoundTrip, callRoundTrip extends Step {}

one sig idFnCall, idFnOut         extends Id {}
one sig qAnsweredBy, qAnswers     extends Step {}
one sig outRoundTrip, fnCallRoundTrip  extends Step {}

// ── The declared facts ──────────────────────────────────────────────────────
// `a tool result answers a tool call which is answered by a tool result` is
// the tool result you started from — and dually. Two equations, and together
// they say `answers` and `answeredBy` are mutually inverse: the bijection.
one sig resultFact, callFact, outFact, fnCallFact extends Fact {}

pred schema {
  Type   = AnAssistantTurn + AUserTurn + AToolCall + AToolResult
         + AFunctionCall + AFunctionCallOutput
  Aspect = callIn + resultIn + answers + answeredBy + outAnswers + outAnsweredBy
  Fact   = resultFact + callFact + outFact + fnCallFact

  callIn.dom     = AToolCall     and callIn.cod     = AnAssistantTurn
  resultIn.dom   = AToolResult   and resultIn.cod   = AUserTurn
  answers.dom    = AToolResult   and answers.cod    = AToolCall
  answeredBy.dom = AToolCall     and answeredBy.cod = AToolResult

  outAnswers.dom    = AFunctionCallOutput and outAnswers.cod    = AFunctionCall
  outAnsweredBy.dom = AFunctionCall       and outAnsweredBy.cod = AFunctionCallOutput

  // Anthropic paths
  idCall.src = AToolCall  and idResult.src = AToolResult
  pAnsweredBy.head = answeredBy and pAnsweredBy.tail = idResult
  pAnswers.head    = answers    and pAnswers.tail    = idCall
  resultRoundTrip.head = answers    and resultRoundTrip.tail = pAnsweredBy
  callRoundTrip.head   = answeredBy and callRoundTrip.tail   = pAnswers

  // OpenAI paths
  idFnCall.src = AFunctionCall and idFnOut.src = AFunctionCallOutput
  qAnsweredBy.head = outAnsweredBy and qAnsweredBy.tail = idFnOut
  qAnswers.head    = outAnswers    and qAnswers.tail    = idFnCall
  outRoundTrip.head    = outAnswers    and outRoundTrip.tail    = qAnsweredBy
  fnCallRoundTrip.head = outAnsweredBy and fnCallRoundTrip.tail = qAnswers

  // the round trips are identities
  resultFact.lhs = resultRoundTrip and resultFact.rhs = idResult
  callFact.lhs   = callRoundTrip   and callFact.rhs   = idCall
  outFact.lhs    = outRoundTrip    and outFact.rhs    = idFnOut
  fnCallFact.lhs = fnCallRoundTrip and fnCallFact.rhs = idFnCall
}

fun anthropicTypes:   set Type   { AnAssistantTurn + AUserTurn + AToolCall + AToolResult }
fun anthropicAspects: set Aspect { callIn + resultIn + answers + answeredBy }
fun anthropicPaths:   set Path   { idCall + idResult + pAnsweredBy + pAnswers
                                 + resultRoundTrip + callRoundTrip }
fun anthropicFacts:   set Fact   { resultFact + callFact }

fun openaiTypes:   set Type   { AFunctionCall + AFunctionCallOutput }
fun openaiAspects: set Aspect { outAnswers + outAnsweredBy }
fun openaiPaths:   set Path   { idFnCall + idFnOut + qAnsweredBy + qAnswers
                              + outRoundTrip + fnCallRoundTrip }
fun openaiFacts:   set Fact   { outFact + fnCallFact }

// The functor runs OpenAI → Anthropic: the OpenAI olog is the smaller one and
// embeds, sending a function call to a tool call and an output to a tool
// result.
//
// The reverse direction is *not* simply blocked — I assumed it was, and the
// solver says otherwise. A translation Anthropic → OpenAI does exist, because
// `callIn` and `resultIn` can be sent to `outAnsweredBy` and `outAnswers`.
// What it cannot do is keep a turn distinct from a block: every such
// translation identifies an assistant turn with a tool result. That is the
// precise sense in which the turn-grouping fails to transport, and both
// halves of it are tested below.
pred embeds[t: Translation] {
  translates[t, openaiTypes, openaiAspects, openaiPaths]
  preservesFacts[t, openaiFacts]
  AFunctionCall.(t.onType)       = AToolCall
  AFunctionCallOutput.(t.onType) = AToolResult
}

test expect {
  // Both formats admit instance data at once.
  bothFormatsRealisable: {
    schema
    instance
    some e: Element | e.isa = AToolCall
    some e: Element | e.isa = AFunctionCall
  } for 10 Element, 6 Type, 6 Aspect, 12 Path, 4 Fact is sat

  // The Anthropic grouping: two distinct results, answering two distinct
  // calls made in one assistant turn, share a single user turn. This is the
  // structure that has no OpenAI counterpart.
  resultsShareOneUserTurn: {
    schema
    instance
    some disj r1, r2: Element | {
      r1.isa = AToolResult
      r2.isa = AToolResult
      r1.(resultIn.act) = r2.(resultIn.act)
      r1.(answers.act) != r2.(answers.act)
      (r1.(answers.act)).(callIn.act) = (r2.(answers.act)).(callIn.act)
    }
  } for 10 Element, 6 Type, 6 Aspect, 12 Path, 4 Fact is sat

  // The measured invariant: no two results answer the same call. This is what
  // the facts buy — `functorial` alone gives each result one call, but says
  // nothing about collisions.
  noTwoResultsAnswerOneCall: {
    schema
    instance
    some disj r1, r2: Element | {
      r1.isa = AToolResult
      r2.isa = AToolResult
      r1.(answers.act) = r2.(answers.act)
    }
  } for 10 Element, 6 Type, 6 Aspect, 12 Path, 4 Fact is unsat

  // ...and the same on the OpenAI side, from its own facts.
  noTwoOutputsAnswerOneCall: {
    schema
    instance
    some disj o1, o2: Element | {
      o1.isa = AFunctionCallOutput
      o2.isa = AFunctionCallOutput
      o1.(outAnswers.act) = o2.(outAnswers.act)
    }
  } for 10 Element, 6 Type, 6 Aspect, 12 Path, 4 Fact is unsat

  // The functor exists and carries the OpenAI round-trip facts to the
  // Anthropic ones. The two formats disagree about turns but agree about
  // pairing, and this is the precise statement of that agreement.
  translationIsAFunctor: {
    schema
    instance
    some t: Translation | embeds[t]
  } for 10 Element, 6 Type, 6 Aspect, 12 Path, 4 Fact, 1 Translation is sat

  // Any translation of the Anthropic olog into the OpenAI olog collapses the
  // distinction between an assistant turn and a tool result. With only two
  // types on the OpenAI side and `callIn`/`resultIn` needing arrows to land
  // on, the turn types are forced onto the block types.
  reverseTranslationCollapsesTurnIntoBlock: {
    schema
    instance
    some t: Translation | {
      translates[t, anthropicTypes, anthropicAspects, anthropicPaths]
      mapsInto[t, anthropicTypes, anthropicAspects, openaiTypes, openaiAspects]
      AnAssistantTurn.(t.onType) != AToolResult.(t.onType)
    }
  } for 10 Element, 6 Type, 6 Aspect, 12 Path, 4 Fact, 1 Translation is unsat

  // ...and that unsat is a real collapse, not an absence: a translation in
  // that direction does exist, and it even preserves the round-trip facts.
  // The reverse direction is degenerate, not impossible.
  reverseTranslationExists: {
    schema
    instance
    some t: Translation | {
      translates[t, anthropicTypes, anthropicAspects, anthropicPaths]
      mapsInto[t, anthropicTypes, anthropicAspects, openaiTypes, openaiAspects]
      preservesFacts[t, anthropicFacts]
    }
  } for 10 Element, 6 Type, 6 Aspect, 12 Path, 4 Fact, 1 Translation is sat
}
