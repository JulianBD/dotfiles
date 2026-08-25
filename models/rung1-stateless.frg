#lang forge

// Rung 1: a user, an agent, and stateless one-off requests.
//
// Written as an olog rather than as a fresh model: the types and aspects below
// are atoms of the `Type` and `Aspect` sigs from olog.frg, so `functorial`
// polices this schema instead of being restated. That reuse is the reason the
// olog rung exists.
//
// Bounds: every test allows 8 elements. An exchange needs five on its own —
// itself, a user, an agent, a prompt, a reply — so Forge's default of 4 makes
// even the simplest conversation unsatisfiable. The unsat results are
// therefore claims about instances of that size, which is what bounded model
// finding always gives.
//
// The content of this rung is mostly an absence. A one-off request is defined
// by what it cannot reach: no history, no store, no other exchange. So the
// tests are largely `unsat`, and the file is short.

open "olog.frg"

option run_sterling off

// The types of this olog. Each is a box, and its label is the comment.
one sig AUser extends Type {}        // a user
one sig AnAgent extends Type {}      // an agent
one sig APrompt extends Type {}      // a prompt
one sig AReply extends Type {}       // a reply
one sig AnExchange extends Type {}   // an exchange: one prompt, one reply

// The aspects. Read each as the paper instructs: source, arrow, target.
one sig asker extends Aspect {}      // an exchange has as asker a user
one sig responder extends Aspect {}  // an exchange has as responder an agent
one sig ask extends Aspect {}        // an exchange has as prompt a prompt
one sig got extends Aspect {}        // an exchange has as reply a reply

// The schema is exactly these boxes and arrows, and nothing else.
pred schema {
  Type = AUser + AnAgent + APrompt + AReply + AnExchange
  Aspect = asker + responder + ask + got

  asker.dom = AnExchange     asker.cod = AUser
  responder.dom = AnExchange responder.cod = AnAgent
  ask.dom = AnExchange       ask.cod = APrompt
  got.dom = AnExchange       got.cod = AReply
}

// One element can reach another when some aspect carries it there.
fun reaches: set Element -> Element {
  { e1: Element, e2: Element | some a: Aspect | e2 in e1.(a.act) }
}

test expect {
  // The schema admits instance data: some conversation actually happens.
  conversationsExist: {
    schema
    functorial
    some e: Element | e.isa = AnExchange
  } for 8 Element is sat

  // Every aspect points *out* of an exchange; nothing points in, so an exchange
  // cannot be named by anything. This holds by construction — `schema` pins
  // every `cod` — so the test is a guard against a careless edit rather than a
  // discovery.
  nothingReferencesAnExchange: {
    schema
    some a: Aspect | a.cod = AnExchange
  } for 8 Element is unsat

  // The statelessness claim proper: no exchange reaches another exchange, at
  // any distance. There is no history to consult and no store to share. Unlike
  // the guard above this one has content, since `reaches` is defined over
  // instance data rather than over the schema, and the check is transitive.
  //
  // It is also not vacuous for want of room: `sameQuestionMayDifferInReply`
  // below exhibits two distinct exchanges within the same bounds, so the
  // unsat result is a real absence of paths, not a shortage of atoms.
  noExchangeReachesAnother: {
    schema
    functorial
    some disj e1, e2: Element | {
      e1.isa = AnExchange
      e2.isa = AnExchange
      e2 in e1.^reaches
    }
  } for 8 Element is unsat

  // Two exchanges may share a user, an agent, and even a prompt, and still
  // hold different replies. Statelessness is not determinism: the same
  // question asked twice may be answered differently.
  sameQuestionMayDifferInReply: {
    schema
    functorial
    some disj e1, e2: Element | {
      e1.isa = AnExchange
      e2.isa = AnExchange
      e1.(ask.act) = e2.(ask.act)
      e1.(responder.act) = e2.(responder.act)
      e1.(got.act) != e2.(got.act)
    }
  } for 8 Element is sat

  // Why memory needs more than an arrow. The temptation is to add `an agent
  // has as reply a reply`, but an agent taking part in several exchanges has
  // several replies, so that arrow is not functional and `functorial` refuses
  // it — the same refusal olog.frg records for `a person has a child`. §2.2.3
  // gives the way out: introduce a type for the many-valued thing, `a list of
  // replies`, and point at that instead. That is a rung of its own, and the
  // same move the tool-calling rung will need, since a response has zero or
  // many tool calls. No test here: the general claim is already tested in
  // olog.frg, and restating it against this schema would only re-derive it.
}
