#lang forge

// Rung 3: kinds.
//
// A kind is what the caller wants back — prose, a command line, a record
// matching a schema. Nothing about it is on the wire: two requests differing
// only in kind are the same HTTP request with a different framing, and the
// reply is the same shape either way. The kind lives entirely on our side.
//
// This rung exists to check a claim I made and then contradicted while
// building. I said kind and protocol were orthogonal — that a request is a
// point in `kind x protocol` and the two factors do not interact. Then
// `zen propose` turned out to need `response_format: json_schema`, which is a
// chat-completions feature; anthropic expresses the same idea through a forced
// tool call and google through `responseSchema`. So the product is partial,
// and this file is where that gets written down properly.
open "category.frg"
open "olog.frg"

// A request carries both a kind and a protocol, and gets back one reply.
one sig ARequest  extends Type {}   // a request
one sig AKind     extends Type {}   // a kind
one sig AProtocol extends Type {}   // a protocol
one sig AReply    extends Type {}   // a reply

one sig kindOf     extends Aspect {}  // a request has as kind a kind
one sig protocolOf extends Aspect {}  // a request has as protocol a protocol
one sig replyOf    extends Aspect {}  // a request has as reply a reply

// Which kinds work over which protocols is a *relation*, not a function: a
// kind may be served by several protocols and a protocol serves several kinds.
// §2.2.3 is explicit that the fix is not to point at "a set of protocols" —
// that only defers the question — but to introduce the relation itself as a
// type with a projection per leg. This is that span, and it is the first place
// in these rungs where one is actually needed.
one sig ASupport extends Type {}   // a support: this kind works over this protocol

one sig supportedKind     extends Aspect {}  // a support has as kind a kind
one sig supportedProtocol extends Aspect {}  // a support has as protocol a protocol

pred schema {
  Type = ARequest + AKind + AProtocol + AReply + ASupport
  Aspect = kindOf + protocolOf + replyOf + supportedKind + supportedProtocol
  no Fact

  kindOf.dom     = ARequest and kindOf.cod     = AKind
  protocolOf.dom = ARequest and protocolOf.cod = AProtocol
  replyOf.dom    = ARequest and replyOf.cod    = AReply

  supportedKind.dom     = ASupport and supportedKind.cod     = AKind
  supportedProtocol.dom = ASupport and supportedProtocol.cod = AProtocol
}

// A request may only pair a kind with a protocol that supports it.
pred wellFormed {
  all r: Element | r.isa = ARequest implies {
    some s: Element | {
      s.isa = ASupport
      s.(supportedKind.act)     = r.(kindOf.act)
      s.(supportedProtocol.act) = r.(protocolOf.act)
    }
  }
}

test expect {
  // The schema admits instance data.
  requestsExist: {
    schema
    instance
    wellFormed
    some r: Element | r.isa = ARequest
  } for 12 Element, 5 Type, 5 Aspect, 4 Path, 9 Arrow, 2 Fact is sat

  // The claim I had wrong. Kind and protocol are *not* independent: a pair may
  // simply have no support, which is `propose` over anthropic. Were they
  // orthogonal the span would have to be the full product and this would be
  // unsat.
  notEveryPairIsSupported: {
    schema
    instance
    some k, p: Element | {
      k.isa = AKind
      p.isa = AProtocol
      no s: Element | {
        s.isa = ASupport
        s.(supportedKind.act)     = k
        s.(supportedProtocol.act) = p
      }
    }
  } for 12 Element, 5 Type, 5 Aspect, 4 Path, 9 Arrow, 2 Fact is sat

  // ...and an unsupported pair cannot be requested. This is the check
  // `propose` performs before it reaches the wire, rather than letting the
  // provider answer with a 400.
  unsupportedRequestImpossible: {
    schema
    instance
    wellFormed
    some r, s: Element | {
      r.isa = ARequest
      s.isa = ASupport
      s.(supportedKind.act) = r.(kindOf.act)
      no t: Element | {
        t.isa = ASupport
        t.(supportedKind.act)     = r.(kindOf.act)
        t.(supportedProtocol.act) = r.(protocolOf.act)
      }
    }
  } for 12 Element, 5 Type, 5 Aspect, 4 Path, 9 Arrow, 2 Fact is unsat

  // The kind is unenforceable. No aspect runs from a reply to a kind, so two
  // requests of different kinds may come back with the very same reply and
  // nothing in the data distinguishes them. This is why `unfence` exists, and
  // why decoding is a partial operation performed on our side rather than a
  // guarantee obtained from the provider.
  repliesDoNotDetermineKind: {
    schema
    instance
    wellFormed
    some disj r1, r2: Element | {
      r1.isa = ARequest
      r2.isa = ARequest
      r1.(kindOf.act)  != r2.(kindOf.act)
      r1.(replyOf.act)  = r2.(replyOf.act)
    }
  } for 12 Element, 5 Type, 5 Aspect, 4 Path, 9 Arrow, 2 Fact is sat

  // The converse, so the previous test is not mistaken for something stronger:
  // one kind may equally be served over two protocols. The span is a genuine
  // relation, constrained in neither direction.
  oneKindMaySpanProtocols: {
    schema
    instance
    some k: Element | some disj s1, s2: Element | {
      k.isa = AKind
      s1.isa = ASupport
      s2.isa = ASupport
      s1.(supportedKind.act) = k
      s2.(supportedKind.act) = k
      s1.(supportedProtocol.act) != s2.(supportedProtocol.act)
    }
  } for 12 Element, 5 Type, 5 Aspect, 4 Path, 9 Arrow, 2 Fact is sat
}
