#lang forge

// Rung 5: extraction — reading a ledger into an olog.
//
// A ledger is a time-ordered sequence of messages written in whatever form the
// model felt like. A cheaper second call reads each message and emits
// sentence-like triples: a subject, a named arrow, an object. Those triples
// accumulate into instance data.
//
// The map from messages to triples is stochastic and lossy, so it is not a
// functor and this file does not pretend otherwise. What it does is make
// "functorial in spirit" precise enough to be checkable, by asking what would
// have to hold for the accumulated triples to *be* an olog instance — and then
// showing exactly which failure modes are possible when they are not.
//
// The result worth having: a contradiction between two extracted triples is
// not a new kind of problem needing new machinery. Two triples sharing a
// subject and an arrow but disagreeing about the object are precisely a
// violation of the functionality of that arrow, which is what `functorial` in
// olog.frg has demanded since rung 0. Contradiction detection is already paid
// for.
//
// With one correction, learned by running an extractor against real prose and
// having it rejected. `coherent` below is a claim about *arrows that are
// aspects*, and not every extracted relation is one. Given "the registry
// resolves an endpoint" and "the registry resolves credentials", both true,
// applying coherence globally calls a many-valued relation a contradiction.
// That is §2.2.3's `a father has a child` exactly: such a relationship is not
// an aspect at all but a span, and no amount of data distinguishes the two
// cases — deciding that `has as protocol` is single-valued while `resolves` is
// not is a modelling judgement made per arrow.
//
// So `coherent` is a constraint one *chooses* to apply to particular arrows,
// not a validity condition on extraction. The tests below say what it does
// when applied; they do not say it should always be.
open "olog.frg"

one sig AMessage extends Type {}  // a message
one sig ATriple  extends Type {}  // an extracted triple
one sig AnEntity extends Type {}  // a thing the triples talk about
one sig AnArrow  extends Type {}  // a named relationship

one sig source  extends Aspect {}  // a triple has as source a message
one sig subject extends Aspect {}  // a triple has as subject a thing
one sig arrow   extends Aspect {}  // a triple has as arrow a named relationship
one sig object  extends Aspect {}  // a triple has as object a thing

// Time. A message precedes another, which is a relation rather than a
// function — a message has no unique successor once branching or retries are
// in play — so it is a span, as in rungs 3 and 4.
one sig APrecedence extends Type {}  // a precedence: this message came before that one

one sig earlier extends Aspect {}  // a precedence has as earlier a message
one sig later   extends Aspect {}  // a precedence has as later a message

pred schema {
  Type = AMessage + ATriple + AnEntity + AnArrow + APrecedence
  Aspect = source + subject + arrow + object + earlier + later
  no Fact

  source.dom  = ATriple and source.cod  = AMessage
  subject.dom = ATriple and subject.cod = AnEntity
  arrow.dom   = ATriple and arrow.cod   = AnArrow
  object.dom  = ATriple and object.cod  = AnEntity

  earlier.dom = APrecedence and earlier.cod = AMessage
  later.dom   = APrecedence and later.cod   = AMessage
}

// Time does not loop.
pred timeIsOrdered {
  no p: Element | p.isa = APrecedence and p.(earlier.act) = p.(later.act)
}

// What it would take for the accumulated triples to form an olog instance:
// each subject-arrow pair determines at most one object. This is the same
// demand `functorial` makes of an aspect, restated over the triples that are
// claiming to describe one.
pred coherent {
  all disj t1, t2: Element |
    (t1.isa = ATriple and t2.isa = ATriple and t1.(subject.act) = t2.(subject.act) and t1.(arrow.act) = t2.(arrow.act))
      implies t1.(object.act) = t2.(object.act)
}

test expect {
  // Extraction produces something.
  extractionsExist: {
    schema
    instance
    timeIsOrdered
    coherent
    some t: Element | t.isa = ATriple
  } for 14 Element, 5 Type, 6 Aspect, 4 Path, 2 Fact is sat

  // Lossy upward: one message may yield several triples.
  oneMessageYieldsManyTriples: {
    schema
    instance
    coherent
    some disj t1, t2: Element | {
      t1.isa = ATriple
      t2.isa = ATriple
      t1.(source.act) = t2.(source.act)
    }
  } for 14 Element, 5 Type, 6 Aspect, 4 Path, 2 Fact is sat

  // Lossy downward: a message may yield none at all. Extraction has no
  // obligation to be surjective onto the ledger, and most chat is not
  // assertions about anything.
  someMessageYieldsNothing: {
    schema
    instance
    coherent
    some m: Element | {
      m.isa = AMessage
      no t: Element | t.isa = ATriple and t.(source.act) = m
    }
  } for 14 Element, 5 Type, 6 Aspect, 4 Path, 2 Fact is sat

  // The failure mode is real: two messages may yield triples that agree on
  // subject and arrow and disagree about the object. Nothing structural
  // prevents a later message contradicting an earlier reading, which is why
  // append-only knowledge needs a detector rather than an overwrite rule.
  laterMessageMayContradictEarlier: {
    schema
    instance
    timeIsOrdered
    some disj t1, t2: Element | some p: Element | {
      t1.isa = ATriple
      t2.isa = ATriple
      p.isa = APrecedence
      p.(earlier.act) = t1.(source.act)
      p.(later.act)   = t2.(source.act)
      t1.(subject.act) = t2.(subject.act)
      t1.(arrow.act)   = t2.(arrow.act)
      t1.(object.act) != t2.(object.act)
    }
  } for 14 Element, 5 Type, 6 Aspect, 4 Path, 2 Fact is sat

  // ...and it is exactly what consistency forbids. The detector is not new
  // machinery: this is the functionality requirement of an aspect, applied to
  // the triples that claim to populate it.
  coherenceRulesOutContradiction: {
    schema
    instance
    coherent
    some disj t1, t2: Element | {
      t1.isa = ATriple
      t2.isa = ATriple
      t1.(subject.act) = t2.(subject.act)
      t1.(arrow.act)   = t2.(arrow.act)
      t1.(object.act) != t2.(object.act)
    }
  } for 14 Element, 5 Type, 6 Aspect, 4 Path, 2 Fact is unsat

  // Two messages may also *agree*, and consistency permits it. Without this
  // the test above would be coherent with reading "never assert the same
  // subject and arrow twice", which would make reinforcement impossible and
  // is not what is wanted.
  distinctMessagesMayAgree: {
    schema
    instance
    coherent
    some disj t1, t2: Element | {
      t1.isa = ATriple
      t2.isa = ATriple
      t1.(source.act) != t2.(source.act)
      t1.(subject.act) = t2.(subject.act)
      t1.(arrow.act)   = t2.(arrow.act)
      t1.(object.act)  = t2.(object.act)
    }
  } for 14 Element, 5 Type, 6 Aspect, 4 Path, 2 Fact is sat
}
