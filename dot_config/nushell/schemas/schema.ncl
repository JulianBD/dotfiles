# JSON has no type system. This is it.
#
# A schema is described once and used at two moments: as a JSON Schema handed
# to the API, where it constrains the decoder so a wrong shape cannot be
# produced, and as a contract checked on the value coming back. Writing those
# separately is how they drift.
#
# The mould can only describe one object's shape. Anything relating two parts
# of a document — every id matched, no two entries contradicting — is beyond
# JSON Schema and stays a contract.

{
  # The mould, for response_format.
  to_json_schema = fun desc =>
    {
      type = "object",
      properties = desc.fields,
      required =
        std.record.fields desc.fields
        |> std.array.filter (fun name =>
          !(std.array.any (fun o => o == name) desc.optional)),
      additionalProperties = false,
    },

  # The contract, generated from the same description so the two cannot
  # disagree about which fields exist.
  Shape = fun desc =>
    std.contract.custom (fun _label value =>
      let missing =
        std.record.fields desc.fields
        |> std.array.filter (fun name =>
          !(std.array.any (fun o => o == name) desc.optional)
          && !(std.record.has_field name value))
      in
      if std.array.length missing != 0 then
        'Error { message = "missing: %{std.string.join ", " missing}" }
      else
        'Ok value
    ),
}
