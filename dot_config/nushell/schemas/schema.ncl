# JSON has no type system. This is it.
#
# A schema is described once, as data, and three artifacts are generated from
# that one description:
#
#   to_json_schema   the mould — handed to the API as response_format, where it
#                    constrains the decoder and costs nothing
#   to_olog          the sentences — a type and one line per aspect, in the
#                    notation of Spivak's ologs, for prompting and for reading
#   Shape            the contract — checked on the way back in
#
# Splitting these by hand is how they drift. The constraints JSON Schema cannot
# express — anything relating two parts of a document — stay as Nickel
# contracts and are checked after the fact, since no mould can enforce them.

let field_names = fun desc => std.record.fields desc.fields in

{
  # The mould. Shape only: this is the subset a decoder can enforce.
  to_json_schema = fun desc =>
    {
      type = "object",
      properties = std.record.map (fun _name f => f.json) desc.fields,
      required =
        field_names desc
        |> std.array.filter (fun name =>
          !(std.array.any (fun o => o == name) desc.optional)),
      additionalProperties = false,
    },

  # The sentences. A type is a singular indefinite noun phrase and an aspect
  # reads as a sentence — Rules 2.1.1 and 2.2.1, which models/olog.frg cannot
  # enforce because it holds no labels. Here the labels exist, so this is the
  # layer where those rules can actually be checked.
  to_olog = fun desc =>
    [desc.noun]
    @ (field_names desc
       |> std.array.map (fun name =>
         "%{desc.noun} %{(std.record.get name desc.fields).sentence}")),

  # The contract. Generated from the same description, so it cannot disagree
  # with the mould about which fields exist.
  Shape = fun desc =>
    std.contract.custom (fun _label value =>
      let missing =
        field_names desc
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
