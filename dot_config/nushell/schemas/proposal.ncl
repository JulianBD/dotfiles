# A proposed command, as returned by `zen propose`.
#
# One description; the JSON Schema in zen.nu is generated from it rather than
# written alongside it.
let s = import "schema.ncl" in

let description = {
  noun = "a proposal",
  fields = {
    shell = {
      json = { type = "string", enum = ["bash", "nu", "fish", "zsh"] },
      sentence = "has as shell a shell",
    },
    command = {
      json = { type = "string" },
      sentence = "has as command a command line",
    },
    destructive = {
      json = { type = "boolean" },
      sentence = "has as risk a risk",
    },
  },
  optional = [],
} in

{
  json_schema = s.to_json_schema description,
  olog = s.to_olog description,
  Contract = s.Shape description,
}
