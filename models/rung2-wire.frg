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
open "category.frg"
open "olog.frg"

// ── The Anthropic olog ──────────────────────────────────────────────────────
// Results are carried by a *user* turn. There is no `tool` role: a tool_use is
// a content block in an assistant turn, a tool_result a content block in a
// user turn, and N results answering N calls share a single user turn.
one sig AnAssistantTurn extends Type {}   // an assistant turn
one sig AUserTurn       extends Type {}   // a user turn
one sig AToolCall       extends Type {}   // a tool call
one sig AToolResult     extends Type {}   // a tool result

// A tool result carries its outcome as structure: `is_error` is a field
// beside the text, not something encoded into it.
one sig AnOutcome   extends Type {}   // an outcome
one sig AResultText extends Type {}   // a tool result's text

one sig outcome    extends Aspect {}  // a tool result has as outcome an outcome
one sig resultText extends Aspect {}  // a tool result has as text a tool result's text

one sig callIn     extends Aspect {}  // a tool call occurs in an assistant turn
one sig resultIn   extends Aspect {}  // a tool result occurs in a user turn
one sig answers    extends Aspect {}  // a tool result answers a tool call
one sig answeredBy extends Aspect {}  // a tool call is answered by a tool result

// ── The OpenAI olog (Responses API) ─────────────────────────────────────────
// Flat items. No turn groups a set of outputs, and there is no analogue of
// `resultIn` — that absence is the whole difference between the two formats.
one sig AFunctionCall       extends Type {}  // a function call
one sig AFunctionCallOutput extends Type {}  // a function call output

// An output carries only a string. There is no error field, so a failure has
// to be written into the text and recovered, if at all, by reading it.
one sig AnOutputText extends Type {}   // an output string

one sig outputText    extends Aspect {}  // an output has as text an output string
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
         + AnOutcome + AResultText
         + AFunctionCall + AFunctionCallOutput + AnOutputText
  Aspect = callIn + resultIn + answers + answeredBy + outcome + resultText
         + outAnswers + outAnsweredBy + outputText
  Fact   = resultFact + callFact + outFact + fnCallFact

  callIn.dom     = AToolCall     and callIn.cod     = AnAssistantTurn
  resultIn.dom   = AToolResult   and resultIn.cod   = AUserTurn
  answers.dom    = AToolResult   and answers.cod    = AToolCall
  answeredBy.dom = AToolCall     and answeredBy.cod = AToolResult

  outcome.dom    = AToolResult and outcome.cod    = AnOutcome
  resultText.dom = AToolResult and resultText.cod = AResultText
  outputText.dom = AFunctionCallOutput and outputText.cod = AnOutputText

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

fun anthropicTypes:   set Type   { AnAssistantTurn + AUserTurn + AToolCall + AToolResult
                                 + AnOutcome + AResultText }
fun anthropicAspects: set Aspect { callIn + resultIn + answers + answeredBy
                                 + outcome + resultText }
fun anthropicPaths:   set Path   { idCall + idResult + pAnsweredBy + pAnswers
                                 + resultRoundTrip + callRoundTrip }
fun anthropicFacts:   set Fact   { resultFact + callFact }

fun openaiTypes:   set Type   { AFunctionCall + AFunctionCallOutput + AnOutputText }
fun openaiAspects: set Aspect { outAnswers + outAnsweredBy + outputText }
fun openaiPaths:   set Path   { idFnCall + idFnOut + qAnsweredBy + qAnswers
                              + outRoundTrip + fnCallRoundTrip }
fun openaiFacts:   set Fact   { outFact + fnCallFact }

// The *core* fragment of each olog: just the call/result pairing, without the
// payload types. The collapse theorem below is a statement about this
// fragment, and only about it.
fun anthropicCoreTypes:   set Type   { AnAssistantTurn + AUserTurn + AToolCall + AToolResult }
fun anthropicCoreAspects: set Aspect { callIn + resultIn + answers + answeredBy }
fun openaiCoreTypes:      set Type   { AFunctionCall + AFunctionCallOutput }
fun openaiCoreAspects:    set Aspect { outAnswers + outAnsweredBy }

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
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact is sat

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
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact is sat

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
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact is unsat

  // ...and the same on the OpenAI side, from its own facts.
  noTwoOutputsAnswerOneCall: {
    schema
    instance
    some disj o1, o2: Element | {
      o1.isa = AFunctionCallOutput
      o2.isa = AFunctionCallOutput
      o1.(outAnswers.act) = o2.(outAnswers.act)
    }
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact is unsat

  // The functor exists and carries the OpenAI round-trip facts to the
  // Anthropic ones. The two formats disagree about turns but agree about
  // pairing, and this is the precise statement of that agreement.
  translationIsAFunctor: {
    schema
    instance
    some t: Translation | embeds[t]
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact, 1 Translation is sat

  // Any translation of the Anthropic *core* into the OpenAI *core* collapses
  // the distinction between an assistant turn and a tool result. With only two
  // types on the target side and `callIn`/`resultIn` needing arrows to land
  // on, the turn types are forced onto the block types.
  //
  // This is a claim about the cores and nothing more, and the boundary is
  // sharper than "a bigger target breaks it". Adding the type `an output
  // string` alone changes nothing — the turn types still have no arrow to
  // land on. Adding the *arrow* `outputText` as well is what lets the
  // collapse escape, and then the theorem fails. Both mutants were run. I had
  // stated this unqualified at first; the solver corrected it.
  coreReverseTranslationCollapsesTurnIntoBlock: {
    schema
    instance
    some t: Translation | {
      translates[t, anthropicCoreTypes, anthropicCoreAspects, anthropicPaths]
      mapsInto[t, anthropicCoreTypes, anthropicCoreAspects, openaiCoreTypes, openaiCoreAspects]
      AnAssistantTurn.(t.onType) != AToolResult.(t.onType)
    }
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact, 1 Translation is unsat

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
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact, 1 Translation is sat

  // Where the loss actually is. A tool result's outcome is independent of its
  // text: two results may carry the same text and still differ in whether
  // they failed. Anthropic keeps that in a field, so it survives; OpenAI has
  // only the string, so the bit has to be written into the text and parsed
  // back out — and this test is the reason that is not merely inconvenient
  // but genuinely lossy.
  outcomeIsIndependentOfText: {
    schema
    instance
    some disj r1, r2: Element | {
      r1.isa = AToolResult
      r2.isa = AToolResult
      r1.(resultText.act) = r2.(resultText.act)
      r1.(outcome.act) != r2.(outcome.act)
    }
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact is sat

  // The negative counterpart, and the honest limit of this rung. One might
  // hope to prove that no translation can carry `outcome` into the OpenAI
  // olog. It can: `outputText` maps onto `outcome` perfectly well, because at
  // the schema level `an output string` and `an outcome` are both just boxes.
  // The model holds no labels — the same reason olog.frg cannot enforce Rules
  // 2.1.1 and 2.2.1 — so the lossiness is not a schema-level fact at all. It
  // is an instance-level one, which is what the test above states.
  outcomeIsInTheImageOfSomeTranslation: {
    schema
    instance
    some t: Translation | {
      translates[t, openaiTypes, openaiAspects, openaiPaths]
      outputText.(t.onAspect) = outcome
    }
  } for 12 Element, 9 Type, 9 Aspect, 12 Path, 4 Fact, 1 Translation is sat
}
