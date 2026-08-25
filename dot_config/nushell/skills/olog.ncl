# Rewrite prose as an olog document.
let s = import "skill.ncl" in
let fmt = import "olog_document.ncl" in

{
  name = "olog",
  description = "Rewrite prose as an olog document in markdown: types as singular indefinite noun phrases, aspects as delimited sentences. Use when turning a model's free-form answer, a transcript or a document into structured knowledge.",
  output = "markdown",
  instructions = m%"
Rewrite the text as an olog, in markdown, in exactly this shape:
%{fmt.example}
Every entry begins with `a` or `an` and is a singular indefinite noun phrase:
write `a dotfile`, not `dotfiles`; `a chezmoi source directory`, not `Chezmoi`.

Separate the three parts of an aspect line with `%{std.string.trim fmt.delimiter}`.
Name the same thing with the same phrase every time. Output the document and
nothing else.
"%,
} | s.Skill
