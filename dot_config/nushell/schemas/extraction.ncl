# What comes back from reading arbitrary prose into structured entries.
#
# Each entry is one assertion: a subject, a named relation, an object. Reading
# a paragraph produces several; reading a paragraph that asserts nothing
# produces none. Both are expected — models/rung5-extraction.frg exhibits each.
let s = import "schema.ncl" in

let entry = {
  type = "object",
  properties = {
    subject = { type = "string" },
    relation = { type = "string" },
    object = { type = "string" },
  },
  required = ["subject", "relation", "object"],
  additionalProperties = false,
} in

let description = {
  fields = {
    entries = { type = "array", items = entry },
  },
  optional = [],
} in

# Entries sharing a subject and relation but differing in object.
#
# NOT applied by default, and the reason is the whole difficulty. Such a pair
# may be a contradiction — the model read one relationship two incompatible
# ways — or it may be a perfectly good many-valued relation: "the registry
# resolves an endpoint" and "the registry resolves credentials" are both true.
# That is §2.2.3's `a father has a child`, and the olog answer is that such a
# relationship is not an aspect at all but a span.
#
# Nothing in the data distinguishes the two cases. Deciding that `has as
# protocol` is single-valued while `resolves` is not is a modelling judgement,
# so this reports rather than rejects, and the caller supplies the judgement.
#
# It is a statement about the whole list, so no decoder-level mould can enforce
# it either way.
let Coherent = std.contract.custom (fun _label value =>
  let clashes =
    value.entries
    |> std.array.fold_left (fun acc a =>
      acc
      @ (value.entries
         |> std.array.filter (fun b =>
           a.subject == b.subject
           && a.relation == b.relation
           && a.object != b.object)
         |> std.array.map (fun b =>
           "%{a.subject} %{a.relation}: %{a.object} vs %{b.object}"))
    ) []
  in
  if std.array.length clashes != 0 then
    'Error { message = "incoherent: %{std.array.first clashes}" }
  else
    'Ok value
) in

{
  json_schema = s.to_json_schema description,
  Contract = s.Shape description,
  Coherent,
}
