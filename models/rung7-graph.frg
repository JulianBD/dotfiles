#lang forge

// Rung 7: the dataflow graph.
//
// Rungs 0 through 6 modelled single requests and single sessions, in which the
// composite of interest was a path: one thing after another. This rung drops
// that assumption. A pipeline is a directed graph of nodes joined by typed
// edges, and the two ways of putting nodes together are sequential composition
// (written `;`) and the tensor product (written `⊗`), which is the setting of a
// symmetric monoidal category. The vocabulary is that of the copy-discard
// fragment: alongside ordinary nodes there are structural morphisms — copy,
// discard, merge, and barrier — which carry no computation but shape the flow.
// The concepts are those of William Waites' Plumbing language; nothing here is
// derived from its source, which is separately licensed.
//
// The two kinds of computing node are distinguished by one property only. A
// pure node denotes a function, total or partial: a map or a filter, the same
// input giving the same output every time. An agent node denotes a stochastic
// process, and may answer differently on two occasions given identical input.
// The whole of the determinism argument below rests on that single difference,
// and on nothing else about what the nodes do.
//
// Cycles are wanted here, not excluded. Earlier rungs forced paths to be finite
// with the idiom `p not in p.^tail`, because a path that contained itself was a
// malformed term. A feedback edge is not malformed; it is how an iterative
// process — a debate run until it settles, a critic loop, a retry — is written
// down. The point of stating it as a cycle is that the graph then stays finite
// while the process it denotes does not, which is why no round type and no
// iteration counter appear anywhere in this file. Acyclicity is available as a
// named predicate so that the tests can show what its presence would cost.
//
// Deliberately absent, and why the omissions are harmless:
//
//   - The monoidal structure is present in its consequences rather than as
//     syntax. There is no term language with `;` and `⊗` as constructors, and
//     no unit object; instead a composite is a subgraph, and the coherence
//     isomorphisms are invisible because the graph representation quotients by
//     them already. String diagrams are the standard justification for that
//     move, so nothing is lost that a test here could observe.
//
//   - Streams are not modelled as sequences. An edge carries a type, not a
//     history, and merge is described by its typing rather than by any
//     interleaving order. Every theorem below quantifies over what is present
//     on an edge, never over how many times or in what order, so the finer
//     structure would be inert.
//
//   - Fairness, backpressure, and termination are absent. The feedback theorem
//     claims only that iteration is expressible without a round type; it makes
//     no claim that any particular loop halts.
//
// From olog.frg this rung reuses Type, for the type an edge carries, and
// Element, for the individual items of context — a vocabulary entry, a defined
// abbreviation, a piece of state — that travel inside the payload. Aspect,
// Path, and Fact are held empty: there are no declared aspects here, so the
// instance-level machinery of Definition 3.2.3 would have nothing to say.
open "category.frg"
open "olog.frg"

// Tests are the whole point of this file, so there is nothing to look at in
// the visualiser; without this, Forge opens Sterling and waits on stdin when
// the run finishes, which looks like a hang.
option run_sterling off

// A node. `inTypes` and `outTypes` are the types the node will accept and
// offer; `introduces` are the context items this node originates; `requires`
// are the items it needs in order to do its work; `beh` is its input-output
// behaviour, left as a relation so that a stochastic node can be many-valued.
abstract sig Node {
  inTypes:    set Type,
  outTypes:   set Type,
  introduces: set Element,
  requires:   set Element,
  beh:        set Element -> Element
}

// A map or a filter: deterministic, total or partial.
sig PureNode extends Node {}

// A stochastic node: the same input may produce different outputs.
sig AgentNode extends Node {}

// The structural morphisms of the copy-discard fragment. They compute nothing,
// which is why they count as deterministic below alongside the pure nodes.
sig CopyNode    extends Node {}  // duplicates one stream to two outputs
sig DiscardNode extends Node {}  // consumes a stream and offers nothing
sig MergeNode   extends Node {}  // interleaves two streams of the same type
sig BarrierNode extends Node {}  // synchronises A ⊗ B into the pair (A, B)

// A directed edge, labelled with the type it carries.
sig Edge {
  from:    one Node,
  to:      one Node,
  carries: one Type
}

// What a type tells a downstream reader. An edge's declared type captures some
// set of context items; anything travelling on that edge and not captured here
// is precisely the hidden context the second theorem is about.
one sig Typing {
  captures: set Type -> Element
}

// The successor relation on nodes, obtained from the edges. `~from` takes a
// node to the edges leaving it and `.to` to their targets, so `^(~from.to)` is
// the transitive closure: all nodes downstream. `^(~to.from)` is the reverse,
// the strict ancestors of a node.
pred wellTyped {
  // An edge cannot connect an output of one type to an input of another.
  all e: Edge | {
    e.carries in e.from.outTypes
    e.carries in e.to.inTypes
  }
}

// The arities of the structural morphisms, which is all there is to say about
// them. Copy leaves the type alone and fans out to two edges; discard has no
// output at all; merge is same-typed on both sides, which is what distinguishes
// it from barrier; barrier takes two distinct types and offers their pair.
pred structural {
  all c: CopyNode | {
    one c.inTypes
    c.outTypes = c.inTypes
    #(c.~from) = 2
  }
  all d: DiscardNode | {
    no d.outTypes
    one d.inTypes
  }
  all m: MergeNode | {
    one m.inTypes
    m.outTypes = m.inTypes
  }
  all b: BarrierNode | {
    #(b.inTypes) = 2
    one b.outTypes
    b.outTypes not in b.inTypes   // the pair type is not either leg's type
  }
}

// A node cannot misdescribe its own output. Whatever a node introduces appears
// in the declared type of every edge leaving it. This is a modest and local
// requirement: a node knows what it just produced.
//
// Note what is *not* required. Items a node inherited from upstream and passes
// along inside its payload need not appear in its declared output type. That
// gap is not an oversight; it is the phenomenon under study.
pred honestAboutOwnOutput {
  all e: Edge | e.from.introduces in e.carries.(Typing.captures)
}

// A barrier's output type is the pair of its two input types, so it captures
// everything both legs declared. This is forced by what a pair type is, not
// assumed as a discipline.
pred barrierDeclaresBothLegs {
  all b: BarrierNode, out: Edge, incoming: Edge |
    (out.from = b and incoming.to = b) implies
      incoming.carries.(Typing.captures) in out.carries.(Typing.captures)
}

// The items actually present in the payload arriving at a node: everything
// introduced anywhere upstream of it, since nothing here deletes context.
fun arriving[n: Node]: set Element {
  (n.^(~to.from)).introduces
}

// The items a downstream reader can know about from the declared types on the
// node's incoming edges.
fun declaredTo[n: Node]: set Element {
  (n.~to).carries.(Typing.captures)
}

// The failure the second theorem is about: a node needs an item that is really
// there in the payload but that no incoming edge's type mentions. The node did
// not introduce it and cannot have been told about it; it is inherited context
// surviving by luck.
pred hiddenContextLeak[n: Node] {
  some i: Element | {
    i in n.requires
    i in arriving[n]
    i not in declaredTo[n]
    i not in n.introduces
  }
}

// A chain of three nodes under sequential composition: A ; B ; C.
pred sequentialChain[a, b, c: Node] {
  some e1, e2: Edge | {
    e1.from = a and e1.to = b
    e2.from = b and e2.to = c
  }
}

// The tensor of two legs followed by a barrier and then a consumer:
// (A ⊗ B) ; barrier ; C. The two legs are sources, so they are independent of
// each other until the barrier joins them.
pred tensorThenBarrier[a, b: Node, bar: BarrierNode, c: Node] {
  a != b
  a != bar and b != bar and c != bar
  a != c and b != c
  some e1, e2, e3: Edge | {
    e1.from = a and e1.to = bar
    e2.from = b and e2.to = bar
    e3.from = bar and e3.to = c
    // nothing else feeds this fragment
    all e: Edge | e.to = bar implies (e = e1 or e = e2)
    all e: Edge | e.to = c implies e = e3
    no e: Edge | e.to = a or e.to = b
  }
}

// Determinism. A pure node, and every structural morphism, denotes a function:
// at most one output per input. An agent node is under no such obligation.
pred pureIsFunctional {
  all n: Node - AgentNode | all i: Element | lone i.(n.beh)
}

// The deterministic region, i.e. the maximal prefix of the graph that contains
// no stochastic step. A node lies inside it when it is not itself an agent node
// and no agent node lies anywhere among its ancestors. The seam is the boundary
// of this region.
pred inDeterministicRegion[n: Node] {
  n not in AgentNode
  no (n.^(~to.from) & AgentNode)
}

// A weakened version, used only to mutation-check the seam theorem: it looks at
// the node alone and forgets its history.
pred locallyPure[n: Node] {
  n not in AgentNode
}

// Acyclicity, in the style earlier rungs applied to paths. Named so the tests
// can measure what it would cost, not imposed.
pred acyclic {
  no n: Node | n in n.^(~from.to)
}

// The graph is a well-formed pipeline.
pred pipeline {
  no Aspect
  no Path
  no Fact
  wellTyped
  structural
}

test expect {

  // ------------------------------------------------------------------
  // Theorem 1. A round is not a type.
  // ------------------------------------------------------------------

  // An iterative process — a debate that runs until it settles — is a cycle in
  // a finite graph. Three nodes and three edges suffice, and the model contains
  // no sig for a round and no field counting iterations, because the unbounded
  // quantity is the number of traversals of the cycle, which is not part of the
  // structure at all.
  feedbackCycleExists: {
    pipeline
    some disj n1, n2, n3: Node | {
      some e1, e2, e3: Edge | {
        e1.from = n1 and e1.to = n2
        e2.from = n2 and e2.to = n3
        e3.from = n3 and e3.to = n1   // the feedback edge
      }
      n1 in n1.^(~from.to)
    }
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 3 Element is sat

  // The cycle is the whole of the trick. Forbid cycles — the finiteness
  // condition earlier rungs used on paths — and a node can no longer be
  // revisited, so an unbounded iteration would have to be spelled out as a
  // finite sequence of distinct nodes, which is exactly where a round type or
  // an iteration counter would have to be introduced.
  acyclicGraphCannotRevisit: {
    pipeline
    acyclic
    some n: Node | n in n.^(~from.to)
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 3 Element is unsat

  // ------------------------------------------------------------------
  // Theorem 2. Sequential composition accumulates hidden context that the
  // tensor does not.
  // ------------------------------------------------------------------

  // Under A ; B ; C, node C can require an item that A introduced, that is
  // genuinely present in what reaches C, and that the declared type of the B→C
  // edge does not mention. B was honest about its own output and still let the
  // inherited item through undeclared. This is the reachable failure: in the
  // run this rung was written for, the sequential arm lost 18 of 27 inherited
  // abbreviations by exactly this route.
  sequentialLeaksInheritedContext: {
    pipeline
    honestAboutOwnOutput
    some a, b, c: Node | {
      sequentialChain[a, b, c]
      hiddenContextLeak[c]
    }
  } for 4 Node, 4 Edge, 4 Type, 4 Object, 4 Element is sat

  // Under (A ⊗ B) ; barrier ; C the same failure is unreachable. Each leg is a
  // source, so it declares everything it introduces; the barrier's output type
  // is the pair of the two leg types, so it captures both; and the barrier
  // declares its own contribution. Every item arriving at C is therefore
  // declared to C. The parallel arm of the same run also lost items — about a
  // dozen — but none of them was inherited, which is what this says.
  tensorAdmitsNoLeak: {
    pipeline
    honestAboutOwnOutput
    barrierDeclaresBothLegs
    some a, b, c: Node, bar: BarrierNode | {
      tensorThenBarrier[a, b, bar, c]
      hiddenContextLeak[c]
    }
  } for 5 Node, 4 Edge, 5 Type, 5 Object, 4 Element is unsat

  // The tensor arrangement is populated, so the unsat above is not for want of
  // room: the same fragment with items flowing through it exists in the same
  // bounds.
  tensorFragmentExists: {
    pipeline
    honestAboutOwnOutput
    barrierDeclaresBothLegs
    some a, b, c: Node, bar: BarrierNode | {
      tensorThenBarrier[a, b, bar, c]
      some a.introduces
      some b.introduces
      some c.requires
    }
  } for 5 Node, 4 Edge, 5 Type, 5 Object, 4 Element is sat

  // The scope of the previous result, stated so that it is not overclaimed.
  // The tensor does not immunise anything by itself: what rules out leakage is
  // that each leg of the fragment above is a source, so it has no inherited
  // context to lose. Give one leg an upstream node of its own and the leg is a
  // sequential composite again, and the failure returns. The honest form of the
  // theorem is therefore that leakage is a property of sequential depth, and
  // that `⊗ ; barrier` removes it exactly to the extent that it replaces depth
  // with width.
  tensorLegThatIsItselfAChainStillLeaks: {
    pipeline
    honestAboutOwnOutput
    barrierDeclaresBothLegs
    some a0, a, b, c: Node, bar: BarrierNode | {
      some e0: Edge | e0.from = a0 and e0.to = a
      some e1, e2, e3: Edge | {
        e1.from = a and e1.to = bar
        e2.from = b and e2.to = bar
        e3.from = bar and e3.to = c
      }
      hiddenContextLeak[c]
    }
  } for 6 Node, 6 Edge, 6 Type, 6 Object, 4 Element is sat

  // ------------------------------------------------------------------
  // Theorem 3. Determinism is confined, and the seam is well defined.
  // ------------------------------------------------------------------

  // A path all of whose nodes are pure denotes a function: one input, at most
  // one output of the composite.
  purePathIsAFunction: {
    pipeline
    pureIsFunctional
    some a, b, c: Node - AgentNode | {
      sequentialChain[a, b, c]
      some i: Element | #(i.((a.beh).(b.beh).(c.beh))) > 1
    }
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 4 Element is unsat

  // One agent node anywhere on the path breaks it. This is the content of the
  // theorem above: functionality was a property of the nodes, not of the shape.
  oneAgentNodeBreaksFunctionality: {
    pipeline
    pureIsFunctional
    some a, c: Node, b: AgentNode | {
      sequentialChain[a, b, c]
      some i: Element | #(i.((a.beh).(b.beh).(c.beh))) > 1
    }
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 4 Element is sat

  // The seam is well defined: the deterministic region is closed downward under
  // the ancestor relation, so it has a unique maximal element and there is no
  // choice about where the boundary falls. A node cannot be inside the region
  // while one of its ancestors is outside.
  seamIsDownwardClosed: {
    pipeline
    some n, p: Node | {
      p in n.^(~to.from)
      inDeterministicRegion[n]
      not inDeterministicRegion[p]
    }
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 3 Element is unsat

  // And the region is a genuine prefix rather than everything or nothing: a
  // graph exists with nodes on both sides of the seam.
  seamHasBothSides: {
    pipeline
    some n, m: Node | {
      inDeterministicRegion[n]
      not inDeterministicRegion[m]
    }
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 3 Element is sat

  // ------------------------------------------------------------------
  // Theorem 4. Typed composition rejects malformed graphs.
  // ------------------------------------------------------------------

  // An edge cannot connect an output of one type to an input of another.
  noMistypedEdge: {
    wellTyped
    some e: Edge | e.carries not in e.from.outTypes or e.carries not in e.to.inTypes
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 3 Element is unsat

  // Without the typing rule such a graph is drawable, which is what makes the
  // rule worth stating.
  mistypedEdgeIsOtherwiseDrawable: {
    some e: Edge | e.carries not in e.to.inTypes
  } for 4 Node, 4 Edge, 3 Type, 3 Object, 3 Element is sat
}
