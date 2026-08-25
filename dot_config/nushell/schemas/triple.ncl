# A sentence-like triple, as extracted from a message.
#
# The extraction rung of models/rung5-extraction.frg: a subject, a named
# arrow, an object. Reading a ledger produces a list of these.
let s = import "schema.ncl" in

let description = {
  noun = "a triple",
  fields = {
    subject = {
      json = { type = "string" },
      sentence = "has as subject a thing",
    },
    arrow = {
      json = { type = "string" },
      sentence = "has as arrow a named relationship",
    },
    object = {
      json = { type = "string" },
      sentence = "has as object a thing",
    },
  },
  optional = [],
} in

{
  json_schema = s.to_json_schema description,
  olog = s.to_olog description,
  Contract = s.Shape description,
}
