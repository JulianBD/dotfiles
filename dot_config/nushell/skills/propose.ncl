# Propose one command line for the user to review.
let s = import "skill.ncl" in

{
  name = "propose",
  description = "Turn a request into one shell command, returned as structured data with the shell it targets and whether it is destructive. Use when the user describes something they want to run.",
  output = "json",
  schema = "proposal",
  instructions = m%"
Turn the request into exactly one command line.

Reply with the command and nothing else: no explanation, no commentary, no
markdown. If the task needs several steps, join them into a single line using
the shell's own syntax.

Prefer widely available tools and options that are safe to run twice. Never
invent flags; if unsure a flag exists, use a simpler form. Mark the command
destructive if it deletes or overwrites anything.
"%,
} | s.Skill
