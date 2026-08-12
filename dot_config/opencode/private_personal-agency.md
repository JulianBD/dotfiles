# Personal agency layer: live capture

Status: captured during conversation, 2026-08-04.  
Audience: me and the agents/models I choose to point here.  
Scope: AI and non-AI work. Not a diagnosis.

Note on rendering: GitHub Flavored Markdown can render LaTeX math arrows, but not Typst/fletcher or TikZ commutative diagrams. The diagrams are therefore written as inline arrow formulas.

## The ur-template

A pursuit begins when present actuality is unsatisfying and some future actuality would be preferable. The work is constructing a passage from one to the other. In the template we have been using, the present actuality is $START$, the preferable future actuality is $END$, and the passage is $HOW$: $START \xrightarrow{HOW} END$.

$START$ is what is already true, available, observed, or owned. $END$ is what should be true afterward. $HOW$ is the mechanism that moves $START$ toward $END$. The important separation is that $END$ is not an artifact. An artifact is only a candidate $HOW$.

A useful $END$ sentence names a changed capability or state for a subject. The examples we used were: future me can re-enter this thought; future agents start with my operating context; future repo operators can run one safe plan; future me can finish without relying on being grokked. If a sentence like that cannot be written, then there is not yet an $END$. There is only pressure to move.

## Artifact versus END

The recurring failure is letting a $HOW$ impersonate an $END$. The pathological shape is $pressure \xrightarrow{generate} artifact \xrightarrow{serves?} purpose$, when the relation that should come first is $pressure \xrightarrow{should\ define\ first} purpose$.

AI makes this failure more likely because path generation is cheap and seductive. A model can produce a plausible $HOW$ very quickly. It can also produce something that looks like an $END$ because an artifact is legible. That does not mean the artifact serves a purpose. The purpose has to be defined before the artifact can be judged as a path.

## Unrouted material

The ideas that feel purposeless are not useless. They are unrouted material. They have real structure, but they do not currently have a $START$ or $END$ attachment. The problem is not their existence. The problem is forcing them into ticket, artifact, or $HOW$ form before they have a route.

The legitimate state for those ideas is parked. Parked does not mean discarded. It means retained with enough structure that they can be routed later when a $START$ or $END$ appears that can receive them.

## Recursion

The template recurses because paths compose: $A \xrightarrow{f} B \xrightarrow{g} C$, with composite $A \xrightarrow{g\circ f} C$.

In the composition $A \xrightarrow{f} B \xrightarrow{g} C$, $B$ is the $END$ of $A \xrightarrow{f} B$ and the $START$ of $B \xrightarrow{g} C$. Nothing is intrinsically a goal, an artifact, or a step. It has a role relative to a morphism.

This recursion explains the pathologies we named. Recursive descent happens when well-specified leaves are completed while the parent $END$ is unresolved. Recursive ascent happens when the meta-model keeps being refined instead of doing a leaf rep. Role collapse happens when $B$ as an artifact is mistaken for $C$ as a purpose. Unbanked thinking happens when a thought changes $B$ privately but never becomes an addressable $START$ for future me.

## Termination rule

Because the template recurses, it needs a termination rule. A node may decompose only until it produces one of three things: a decision I can make, a rep I can do or verify, or a parkable object with enough structure to route later. If decomposition does not produce one of those, it is not work. It is motion.

## Role-truthful modes

Before choosing grill, research, implement, or any other mode, the session object has to be classified. The classification we discussed is whether the work is observing $START$, discovering $END$, constraining $HOW$, executing a path, or parking unrouted material.

Low spoons, production risk, external comments, git mutation, and remote state are constraints on admissible $HOW$s. They should not redefine the $END$. They determine which paths are allowed, not what the purpose is.

## Current working principle

Every artifact must name its parent morphism. Every session must name the level it is working on and the base case that stops recursion.
