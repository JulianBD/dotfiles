#set document(title: "Personal agency layer: live capture")
#set page(
  "us-letter",
  margin: (x: 1in, y: 0.95in),
  numbering: "1",
)
#set text(
  font: ("Charter", "Libertinus Serif"),
  size: 11pt,
  lang: "en",
)
#show math.equation: set text(font: "New Computer Modern Math")
#set par(
  justify: true,
  linebreaks: "optimized",
  leading: 0.68em,
  spacing: 0.68em,
  first-line-indent: 1.2em,
)
#set block(spacing: 1.1em)
#set heading(numbering: none)
#show heading.where(level: 1): set text(size: 14pt, weight: "bold")
#show heading.where(level: 1): set block(above: 1.5em, below: 0.7em)

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let fig(body) = block(above: 1.1em, below: 1.1em)[#align(center)[#body]]

#align(center)[
  #text(size: 17pt, weight: "bold")[Personal agency layer]
  #linebreak()
  #text(size: 11.5pt)[live capture]
]

#v(0.8em)

Status: captured during conversation, 2026-08-04.\
Audience: me and the agents/models I choose to point here.\
Scope: AI and non-AI work. Not a diagnosis.

= The ur-template

A pursuit begins when present actuality is unsatisfying and some future actuality would be preferable. The work is constructing a passage from one to the other. In the template we have been using, the present actuality is START, the preferable future actuality is END, and the passage is HOW.

#fig(diagram(
  node-stroke: 0.6pt,
  edge-stroke: 0.6pt,
  label-size: 0.85em,
  spacing: 5em,
  node((0, 0), [START], name: <start>),
  node((2, 0), [END], name: <end>),
  edge(<start>, <end>, [HOW], "->"),
))

START is what is already true, available, observed, or owned. END is what should be true afterward. HOW is the mechanism that moves START toward END. The important separation is that END is not an artifact. An artifact is only a candidate HOW.

A useful END sentence names a changed capability or state for a subject. The examples we used were: future me can re-enter this thought; future agents start with my operating context; future repo operators can run one safe plan; future me can finish without relying on being grokked. If a sentence like that cannot be written, then there is not yet an END. There is only pressure to move.

= Artifact versus END

The recurring failure is letting a HOW impersonate an END.

#fig(diagram(
  node-stroke: 0.6pt,
  edge-stroke: 0.6pt,
  label-size: 0.85em,
  spacing: 4em,
  node((0, 0), [pressure], name: <pressure>),
  node((1, 0), [artifact], name: <artifact>),
  node((2, 0), [purpose], name: <purpose>),
  edge(<pressure>, <artifact>, [generate], "->"),
  edge(<artifact>, <purpose>, [serves?], "->", label-side: center),
  edge(<pressure>, <purpose>, [should define first], "->", bend: -35deg),
))

AI makes this failure more likely because path generation is cheap and seductive. A model can produce a plausible HOW very quickly. It can also produce something that looks like an END because an artifact is legible. That does not mean the artifact serves a purpose. The purpose has to be defined before the artifact can be judged as a path.

= Unrouted material

The ideas that feel purposeless are not useless. They are unrouted material. They have real structure, but they do not currently have a START or END attachment. The problem is not their existence. The problem is forcing them into ticket, artifact, or HOW form before they have a route.

The legitimate state for those ideas is parked. Parked does not mean discarded. It means retained with enough structure that they can be routed later when a START or END appears that can receive them.

= Recursion

The template recurses because paths compose.

#fig(diagram(
  node-stroke: 0.6pt,
  edge-stroke: 0.6pt,
  label-size: 0.85em,
  spacing: 4em,
  node((0, 0), $A$, name: <a>),
  node((1, 0), $B$, name: <b>),
  node((2, 0), $C$, name: <c>),
  edge(<a>, <b>, $f$, "->"),
  edge(<b>, <c>, $g$, "->"),
  edge(<a>, <c>, $g compose f$, "->", bend: -35deg),
))

In the composition $A -> B -> C$, $B$ is the END of $A -> B$ and the START of $B -> C$. Nothing is intrinsically a goal, an artifact, or a step. It has a role relative to a morphism.

This recursion explains the pathologies we named. Recursive descent happens when well-specified leaves are completed while the parent END is unresolved. Recursive ascent happens when the meta-model keeps being refined instead of doing a leaf rep. Role collapse happens when $B$ as an artifact is mistaken for $C$ as a purpose. Unbanked thinking happens when a thought changes $B$ privately but never becomes an addressable START for future me.

= Termination rule

Because the template recurses, it needs a termination rule. A node may decompose only until it produces one of three things: a decision I can make, a rep I can do or verify, or a parkable object with enough structure to route later. If decomposition does not produce one of those, it is not work. It is motion.

= Role-truthful modes

Before choosing grill, research, implement, or any other mode, the session object has to be classified. The classification we discussed is whether the work is observing START, discovering END, constraining HOW, executing a path, or parking unrouted material.

Low spoons, production risk, external comments, git mutation, and remote state are constraints on admissible HOWs. They should not redefine the END. They determine which paths are allowed, not what the purpose is.

= Current working principle

Every artifact must name its parent morphism. Every session must name the level it is working on and the base case that stops recursion.
