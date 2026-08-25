#lang forge

// Rung 4: session management, and the two stores.
//
// Every call is logged; only some calls belong to a session. The distinction
// that matters is not length but the *read* path: a history entry is never fed
// back into a later request, while a session's turns are. Recording a one-off
// therefore does not make any later call depend on it, which is rung 1's
// statelessness restated in terms of what reaches the model rather than what
// exists on disk.
open "olog.frg"

one sig ARequest extends Type {}  // a request
one sig AnEntry  extends Type {}  // a history entry
one sig ASession extends Type {}  // a session
one sig ATurn    extends Type {}  // a stored turn

// A request belongs to at most one session, and most belong to none. That is
// a partial relation, so it cannot be an aspect — §2.2.3's span again, as in
// rung 3. The apex is the act of using a session, which exists only when the
// call was made with --session.
one sig AUse extends Type {}      // a use: this request draws on this session

one sig logs    extends Aspect {}  // a request has as entry a history entry
one sig entryOf extends Aspect {}  // a history entry has as request a request
one sig turnOf  extends Aspect {}  // a stored turn has as session a session

one sig usedBy      extends Aspect {}  // a use has as request a request
one sig usesSession extends Aspect {}  // a use has as session a session

// Paths for the two round trips below.
one sig idRequest, idEntry     extends Id {}
one sig pEntryOf, pLogs        extends Step {}
one sig rtRequest, rtEntry     extends Step {}

// Every call gets its own line: logging is a bijection between requests and
// history entries, declared as a pair of mutually inverse aspects. Injectivity
// then follows rather than being asserted — it is `factsForceInjectivity` from
// olog.frg applied to this schema, a split mono being monic.
one sig requestFact, entryFact extends Fact {}

pred schema {
  Type   = ARequest + AnEntry + ASession + ATurn + AUse
  Aspect = logs + entryOf + turnOf + usedBy + usesSession
  Fact   = requestFact + entryFact

  logs.dom    = ARequest and logs.cod    = AnEntry
  entryOf.dom = AnEntry  and entryOf.cod = ARequest
  turnOf.dom  = ATurn    and turnOf.cod  = ASession

  usedBy.dom      = AUse and usedBy.cod      = ARequest
  usesSession.dom = AUse and usesSession.cod = ASession

  idRequest.src = ARequest and idEntry.src = AnEntry
  pEntryOf.head = entryOf and pEntryOf.tail = idRequest
  pLogs.head    = logs    and pLogs.tail    = idEntry
  rtRequest.head = logs    and rtRequest.tail = pEntryOf
  rtEntry.head   = entryOf and rtEntry.tail   = pLogs

  requestFact.lhs = rtRequest and requestFact.rhs = idRequest
  entryFact.lhs   = rtEntry   and entryFact.rhs   = idEntry
}

// A request draws on at most one session. Nothing in the span forces this —
// a request could perfectly well have two uses — so it is a constraint, and
// the test below is what gives it teeth.
pred oneSessionPerRequest {
  all r: Element | r.isa = ARequest implies {
    lone u: Element | u.isa = AUse and u.(usedBy.act) = r
  }
}

// What informs a request: the turns of the session it uses, and nothing else.
//
// Note what is *not* here. No history entry appears in this relation, and no
// aspect leaves AnEntry at all, so an entry cannot inform anything however the
// instance data falls. That is the read-path guarantee — but it holds by
// construction rather than by discovery, so it is stated here and deliberately
// not dressed up as a test. Pinning it with `is unsat` would only re-derive
// the schema, which is the trap rung 1's `memoryIsNotAnAspect` fell into.
fun informs: set Element -> Element {
  { t: Element, r: Element |
      some u: Element | {
        u.isa = AUse
        u.(usedBy.act) = r
        t.(turnOf.act) = u.(usesSession.act)
      }
  }
}

test expect {
  // Sessions, turns and one-offs coexist.
  storesExist: {
    schema
    instance
    oneSessionPerRequest
    some r: Element | r.isa = ARequest
    some t: Element | t.isa = ATurn
  } for 12 Element, 5 Type, 5 Aspect, 6 Path, 2 Fact is sat

  // A one-off: a request with no use, hence informed by nothing, yet still
  // carrying a history entry. Statelessness and being recorded are compatible,
  // which is the whole reason the stores are separate.
  oneOffIsLoggedButUninformed: {
    schema
    instance
    oneSessionPerRequest
    some r: Element | {
      r.isa = ARequest
      no u: Element | u.isa = AUse and u.(usedBy.act) = r
      no informs.r
      one r.(logs.act)
    }
  } for 12 Element, 5 Type, 5 Aspect, 6 Path, 2 Fact is sat

  // A session request, by contrast, is informed. Without this the test above
  // would be consistent with `informs` being empty for everything.
  sessionRequestIsInformed: {
    schema
    instance
    oneSessionPerRequest
    some r: Element | {
      r.isa = ARequest
      some informs.r
    }
  } for 12 Element, 5 Type, 5 Aspect, 6 Path, 2 Fact is sat

  // No two requests share a history entry. This is not stipulated: it follows
  // from the two declared facts making `logs` a split monomorphism.
  noTwoRequestsShareAnEntry: {
    schema
    instance
    some disj r1, r2: Element | {
      r1.isa = ARequest
      r2.isa = ARequest
      r1.(logs.act) = r2.(logs.act)
    }
  } for 12 Element, 5 Type, 5 Aspect, 6 Path, 2 Fact is unsat

  // A request cannot draw on two sessions at once, so there is never a
  // question of which ledger a reply belongs to.
  noRequestDrawsOnTwoSessions: {
    schema
    instance
    oneSessionPerRequest
    some r: Element | some disj u1, u2: Element | {
      r.isa = ARequest
      u1.isa = AUse
      u2.isa = AUse
      u1.(usedBy.act) = r
      u2.(usedBy.act) = r
    }
  } for 12 Element, 5 Type, 5 Aspect, 6 Path, 2 Fact is unsat
}
