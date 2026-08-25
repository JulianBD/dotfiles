# The markdown projection.
#
# Nickel holds the schema; JSON is one projection of it and markdown is the
# other. Models write and read markdown far better than JSON, and a person can
# read it without tooling — but plain prose is ambiguous to parse, and "a model
# id has as prefix a provider key" reads to any splitter as subject "a model".
#
# So: markdown with one explicit delimiter. Readable as a document, parseable
# without a model. That removes a whole model call from the pipeline and makes
# the step deterministic.

{
  # The section headings the document uses.
  types_heading = "## Types",
  aspects_heading = "## Aspects",

  # What separates the three parts of an aspect line. Chosen because it does
  # not occur in English noun phrases and survives markdown rendering.
  delimiter = " :: ",

  # A worked example, given to the model verbatim. Showing the shape costs
  # fewer tokens than describing it, and it does not invite the model to
  # reason about the rules.
  example = m%"
## Types

- a beam of sunlight
- a white appearance
- an atmosphere of Earth

## Aspects

- a beam of sunlight :: has as appearance :: a white appearance
- a beam of sunlight :: enters :: an atmosphere of Earth
"%,
}
