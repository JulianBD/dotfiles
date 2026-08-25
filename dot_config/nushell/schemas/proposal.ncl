# A proposed command, as returned by `zen propose`.
let s = import "schema.ncl" in

let description = {
  fields = {
    shell = { type = "string", enum = ["bash", "nu", "fish", "zsh"] },
    command = { type = "string" },
    destructive = { type = "boolean" },
  },
  optional = [],
} in

{
  json_schema = s.to_json_schema description,
  Contract = s.Shape description,
}
