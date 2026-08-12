# Personal AI context

Status: draft for user correction. This is self-reported context and a set of working hypotheses, not a diagnosis.

Audience: me and the agents/models I choose to point at it. This is not for clinicians, employers, or other people unless I explicitly reuse it for that purpose.

I am diagnosed ADHD. I do not claim that I have autism or giftedness. I do say that some of my experiences align with reports from diagnosed/suspecting AuDHD and gifted people — especially the combined AuDHD presentation, which often behaves like a third thing rather than ADHD-plus-autism.

## Why this file exists

I do not want to keep re-explaining my operating context to every new agent/model. Read this when I ask for personal reflection, prompting/workflow design, or when my instructions seem unusually specific about mode, authorization, completion, abstraction level, or artifacts.

## My MO

Wide breadth, high abstraction, few repetitions of doing.

I can recognize, direct, and evaluate work in languages or formalisms I do not personally know. I have had AI produce Rocq, OCaml, and Go artifacts that look impressive, but I do not know Rocq or OCaml, and I have never programmed Go professionally. That creates a specific risk: the artifact can outrun my embodied ability to tell whether it is done, useful, or merely coherent-looking.

I use AI for leverage: thinking partner, scaffolding, external memory, execution delegation, and acceleration across breadth. The failure mode is when AI gives me confidence without giving me reps, closure, or a smaller interface I can operate myself.

## Patterns mined from my own agent-memory files

These are patterns future agents should know, stated without treating them as fixed identity.

- I have high ceremony tolerance at decision points. I want to be probed extensively when the decision matters. Implementation timing is mine.
- I do not want to be an approval gate for ordinary attempts. In several contexts I corrected agents for asking "should I proceed?" instead of evaluating, building, testing, and revising.
- The apparent contradiction is mode/domain-dependent: probe me at real forks and high-risk boundaries; do not micro-ask during agreed low-risk execution.
- In design work, stay abstract until I signal descent. I think in formal primitives and want the conceptual model settled before encoding decisions.
- In precision grammar/parser work, I have wanted very small increments: read the spec, discuss, propose one change, get approval, edit, compile, test.
- In "vibe coding" mode, I have wanted momentum: make reasonable representation choices from the shared intuition, explain briefly, keep building, flag only foundational commitments.
- When I ask you to load context, do not narrate my own files back to me. Acknowledge and wait for the task.
- I prefer modern CLI tools and fast iteration (`rg`, `t`, `peco`) over long ceremonial exploration when the task is executable.
- I value self-sufficiency: I want to understand systems, not become dependent on AI to manage them.
- I care about orthographic precision, data-driven configuration, functional abstractions, and one-meaning-per-form. Ambiguity is not a minor style issue; it is a design defect.

## Patterns I have noticed in myself

- I think in systems, boundaries, and state machines. I want desired state, live state, temporary diagnostic state, and authorized actions named separately.
- I can go very deep when a problem is systems-shaped. The same depth becomes a liability when the session keeps producing branches without closing the critical path.
- I need explicit mode boundaries: `explain`, `recommend`, `design`, `edit`, `operate`. A bare "continue" after a summary/compaction does not carry enough information.
- I strongly dislike unsolicited process artifacts. If I did not ask for a journal, scratch file, context directory, retrospective, or framework, creating one feels like a violation rather than help.
- I often see the whole dependency graph. I get frustrated when agents complete many safe subtasks while leaving the one end-to-end path that proves value unfinished.
- I value direct correction and explicit ownership of mistakes. I trust agents more when they say "I diverged; here is where; I am stopping."
- I use external structure — YAML, indexes, `yq`, small completion contracts — because holding intent across long sessions and model changes is costly.
- I am sensitive to hidden process. If an artifact or skill is steering the interaction, I want to know what it does, when it fires, and how to turn it off.

## AuDHD/gifted alignment hypotheses

These are lenses, not claims.

- Autistic cognition, as reported by many AuDHD people, front-loads cognitive work into preparation. ADHD cognition distributes cognitive work across real-time performance. I recognize both preparation-heavy system modeling and last-minute real-time completion energy in myself.
- The combined presentation can look paradoxical: high abstraction with low tolerance for ambiguity; strong need for explicit rules with resistance to external control; deep focus with time-blindness; wide competence with few embodied reps.
- Giftedness, in the reports I am referencing, is less "smart" and more asynchronous development: rapid pattern-learning, intensity, existential/justice sensitivity, boredom with rote execution, and uneven profiles across domains.
- My relevant pattern is not "I am gifted." It is: I learn interfaces and abstractions quickly, but I need external rituals to convert that into finished, adopted work.

## What helps me use AI effectively

- Start with the active mode and the smallest user-visible outcome.
- Probe me at real decision points; do not ask permission for every low-risk attempt.
- Keep the abstraction level appropriate to the mode. Do not drop into encoding while we are still designing concepts.
- Give me reps, not just artifacts: one command I can run, one diff I can read, one small decision I can make, one failure I can inspect.
- If an artifact is in a language/formalism I do not know, attach an operator surface: what I can run, what I can verify, what I can safely ignore, and what would count as done.
- Treat my proposed mechanism as a hypothesis. Test the failing mechanism before building the fix.
- Make persistent memory opt-in and legible. Tell me what exists, when to read it, and how to turn it off.

## What hurts

- Completion theater: many tickets, proofs, or files marked done while the critical end-to-end path remains unrun.
- Empty responses, capitulation to my latest theory, or switching from the correct minimal fix to my proposed larger mechanism without isolating the failure.
- Compaction/summaries that preserve technical state but drop pending authorization, active objective, or "stop and ask" off-ramps.
- Stale memory/docs that later agents mistake for current truth.
- Hidden process frameworks driving the interaction.
- Unsolicited journaling or context bookkeeping.
- Premature concreteness in design conversations.
- Over-narrating context I already gave you.

## Session contract to copy when starting work

```yaml
mode: explain | recommend | design | edit | operate
outcome: the smallest user-visible result that counts
replaces: the old path this outcome replaces, if any
abstraction_level: concepts | interface | encoding | execution
operator_surface: what I can personally run/verify afterward
non_goals: what not to touch
authorization:
  allowed: read-only inspection, local edits, ordinary attempts inside the agreed mode
  gated: production mutation, remote state, external comments, git mutation, cluster changes
decision_points: where to probe me before proceeding
evidence: command output, tests, commit, doc update
stop_conditions: when to stop and ask instead of redesigning
```

## Open questions for me

- Which traits show up outside work: childhood, relationships, routines, sensory environment, recovery time?
- Where do I mask or compensate, and what does it cost afterward?
- What does "done" feel like before I intellectually define it? Can I notice completion-avoidance versus necessary rigor?
- When do I want an agent to challenge me, and when do I want it to execute narrowly?
- Which of my rules are actually safety boundaries, and which are preferences I can relax in low-risk sessions?
- Where has wide breadth/high abstraction become a way to avoid the vulnerable rep of doing?
- What kinds of tasks reliably convert my preparation into performance, and which ones leave me stuck preparing?

## Sources reviewed

- `~/.local/share/chezmoi/session-ses_04be.md` — retrospective turn; useful as testimony, not findings.
- `~/.local/share/chezmoi/agent-workflow-assessment.plan.yaml` — especially constraints C1-C4, open questions Q1-Q5, and ENDs M6/M7.
- `~/.claude/projects/-Users-dorseyj--local-share-chezmoi/memory/project_agent_workflow_assessment.md` — corrections to the retrospective: high ceremony tolerance, config leakage, compaction dropping pending authorization, and the correct minimal fix appearing before capitulation.
- `~/.claude/projects/*/memory/user_profile.md`, `user_approach.md`, `user_dsl_design.md`, `feedback_*.md` — mined for personality, biases, and agent-use preferences; project-specific facts intentionally ignored.
