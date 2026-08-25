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
  // the guard above this one has content: drop `functorial` and it goes sat.
  //
  // At this rung one step would already suffice, since no aspect has an
  // exchange as codomain, so `^` is not doing work today. It is here so the
  // test keeps its meaning once a later rung adds an arrow *into* `an
  // exchange` — at which point the depth is the whole question.
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
      e1.(asker.act) = e2.(asker.act)
      e1.(ask.act) = e2.(ask.act)
      e1.(responder.act) = e2.(responder.act)
      e1.(got.act) != e2.(got.act)
    }
  } for 8 Element is sat

  // Why memory needs more than an arrow — and why this rung cannot yet say so.
  // The temptation is to add `an agent has as reply a reply`. The intended
  // relationship is not functional, since an agent taking part in several
  // exchanges has several replies. But `functorial` does *not* refuse the
  // arrow: adding it and asserting the awkward case — two exchanges, one
  // responder, different replies — comes back sat. `functorial` only demands
  // the agent have exactly one reply; nothing ties that reply to `got`.
  //
  // What would refuse it is a fact (§2.3): the path equivalence
  // `responder ; agentReply = got`, which forces the agent's single reply to
  // be every exchange's reply and collapses the two. This is the first place
  // the fact-free omission in olog.frg actually bites, and it is the reason
  // there is no test here. The general non-functionality claim is not a
  // theorem this meta-model can state, because the model holds no labels and
  // so cannot know which relationship an arrow is meant to denote.
  //
  // §2.2.3 raises `a father has a set of children` only to set it aside — the
  // relationship between `a child` and `a set of children` "becomes an issue
  // to deal with later" — and offers instead a span: a type for the relation
  // R ⊆ A₁ × … × Aₙ with a projection aspect per leg. A span needs only a type
  // and two aspects, so unlike facts it is expressible here today. That is the
  // move the history rung wants, and the tool-calling rung after it, since a
  // response has zero or many tool calls.
}
