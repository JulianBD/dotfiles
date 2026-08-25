# What a skill is, and how it is rendered.
#
# The harness is generic; everything specific is configuration. A skill
# declares what it asks for, how it wants the answer shaped, and which model
# should do it — and one driver runs any of them over messages, sessions and
# turns. Adding a capability means adding a .ncl file, not a nushell command.
#
# The rendered form is a standard SKILL.md: YAML frontmatter with `name` and
# `description`, then the body. That is deliberately not our own format — it is
# what Claude Code and the Agent Skills spec read, so a skill defined here works
# in this harness *and* there, from one definition.

let Output = std.contract.custom (fun _label value =>
  if value == "markdown" || value == "json" then
    'Ok value
  else
    'Error { message = "output must be \"markdown\" or \"json\", got \"%{value}\"" }
) in

{
  # A skill definition. `schema` names a .ncl in the schemas directory and is
  # required only when output is "json".
  Skill = {
    name | String,
    description | String,
    instructions | String,
    output | Output | default = "markdown",
    schema | String | optional,
    model | String | optional,
    max_tokens | Number | default = 4000,
  },

  # The standard SKILL.md rendering.
  #
  # Frontmatter carries only name and description because that is all a harness
  # preloads — the body is read on demand, which is what keeps a large skill
  # library from filling the context window.
  to_markdown = fun skill =>
    m%"---
name: %{skill.name}
description: %{skill.description}
---

%{skill.instructions}
"%,
}
