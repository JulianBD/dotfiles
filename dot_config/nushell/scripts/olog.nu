use ./schema.nu

# Turn extracted entries into an olog.
#
#   zen chat "..." | zen olog | olog parse
#   zen chat "..." | zen olog | olog parse | olog frg --name rung6-domain
#
# `zen olog` produces a markdown document; everything here reads it. No model
# call: the document is delimited, so parsing it is deterministic. That was the
# point of choosing delimited markdown over plain sentences.
#
# What this cannot decide is which arrows are aspects. An extracted relation
# that is many-valued is a span, not an aspect (§2.2.3), and no fold can tell
# the two apart — `olog aspects` reports the ambiguity rather than guessing.

# English noun phrase to a Forge identifier: "a registry" -> ARegistry.
def identifier [
    phrase: string  # A noun phrase, usually beginning with an article
]: nothing -> string {
    let words: list<string> = (
        $phrase
        | str lowercase
        | str replace --all --regex '[^a-z0-9 ]' ' '
        | split row " "
        | where {|w| $w != "" }
    )
    let rest: list<string> = if ($words | first) in ["a" "an" "the"] { $words | skip 1 } else { $words }
    let body: string = ($rest | each {|w| $w | str capitalize } | str join "")

    # The article is recomputed from the noun rather than copied from the
    # phrase, since a phrase that arrived without one still needs a correct
    # article here: "information" -> AnInformation, not AInformation.
    # 0..<1, not 0..1: nushell's substring range is inclusive at both ends, so
    # 0..1 returns two characters.
    let initial: string = ($body | str substring 0..<1 | str lowercase)
    let article: string = if $initial in ["a" "e" "i" "o" "u"] { "An" } else { "A" }
    $"($article)($body)"
}

# Relation phrase to a Forge identifier: "has as prefix" -> hasAsPrefix.
#
# Aspects take no article: the phrase is a verb, not a noun.
def aspect-identifier [
    phrase: string  # A relation phrase
]: nothing -> string {
    let words: list<string> = (
        $phrase
        | str lowercase
        | str replace --all --regex '[^a-z0-9 ]' ' '
        | split row " "
        | where {|w| $w != "" }
    )
    if ($words | is-empty) { return "relates" }
    let head: string = ($words | first)
    let tail: list<string> = ($words | skip 1 | each {|w| $w | str capitalize })
    $"($head)($tail | str join '')"
}

# Read an olog document into types and aspects.
#
# Deterministic. The delimiter is what makes it so — plain prose cannot be
# split, since "a model id has as prefix a provider key" reads to any splitter
# as subject "a model".
#
# Types are collected from the Types section *and* from the endpoints of every
# aspect, so a type used but never declared is not lost.
export def parse []: string -> record<types: list<string>, aspects: table> {
    let doc: record = (schema document olog_document)
    let lines: list<string> = ($in | lines | each {|l| $l | str trim })

    let bullets: list<string> = (
        $lines
        | where {|l| $l starts-with "- " or $l starts-with "* " }
        | each {|l| $l | str substring 2.. | str trim }
    )

    let aspects: table = (
        $bullets
        | where {|b| $b =~ ($doc.delimiter | str trim) }
        | each {|b|
            let parts: list<string> = (
                $b | split row ($doc.delimiter | str trim) | each {|p| $p | str trim }
            )
            {
                subject: ($parts | get -o 0 | default ""),
                relation: ($parts | get -o 1 | default ""),
                object: ($parts | get -o 2 | default "")
            }
        }
        | where {|a| $a.subject != "" and $a.object != "" }
    )

    let declared: list<string> = (
        $bullets | where {|b| not ($b =~ ($doc.delimiter | str trim)) }
    )
    let used: list<string> = (
        ($aspects | get subject) ++ ($aspects | get object)
    )

    {types: ($declared ++ $used | uniq | sort), aspects: $aspects}
}

# The distinct things the olog talks about, as types.
export def types []: record -> table<phrase: string, id: string> {
    $in | get types | each {|phrase| {phrase: $phrase, id: (identifier $phrase)} }
}

# The arrows, with the types they run between.
#
# `single` is false when the same subject and relation reach more than one
# object anywhere in the entries. Such an arrow is not an aspect: it is either
# a contradiction or a genuinely many-valued relation, and which one is a
# judgement this cannot make.
export def aspects []: record -> table {
    $in
    | get aspects
    | group-by relation
    | transpose relation rows
    | each {|group| {
        relation: $group.relation,
        id: (aspect-identifier $group.relation),
        dom: ($group.rows | get subject | uniq),
        cod: ($group.rows | get object | uniq),
        single: (
            ($group.rows
             | group-by {|r| $r.subject }
             | transpose k v
             | all {|pair| ($pair.v | get object | uniq | length) == 1 })
        )
    } }
}

# The entries as olog sentences, one per line.
export def sentences []: record -> list<string> {
    $in | get aspects | each {|e| $"($e.subject) ($e.relation) ($e.object)" }
}

# A Forge schema, ready to sit beside the hand-written rungs.
#
# Emits types and aspects only. No facts: a fact is a path equivalence, and
# nothing in a flat list of entries states one. Arrows that are not
# single-valued are emitted commented out, with the reason, because declaring
# them as aspects would make `functorial` unsatisfiable and the file would look
# broken rather than under-specified.
export def frg [
    --name: string = "extracted"  # Used in the header comment only
]: record -> string {
    let olog: record = $in
    let ts: table = ($olog | types)
    let asp: table = ($olog | aspects)
    let good: table = ($asp | where single)
    let ambiguous: table = ($asp | where not single)

    let type_lines: string = (
        $ts | each {|t| $"one sig ($t.id) extends Type {}   // ($t.phrase)" } | str join "\n"
    )
    let aspect_lines: string = (
        $good
        | each {|a| $"one sig ($a.id) extends Aspect {}  // ($a.dom | first) ($a.relation) ($a.cod | first)" }
        | str join "\n"
    )
    let ambiguous_lines: string = (
        if ($ambiguous | is-empty) { "" } else {
            let header: string = "\n// Not emitted as aspects: these relations reach more than one object from\n// the same subject, so they are spans rather than aspects (§2.2.3), or the\n// extraction contradicted itself. Decide which before declaring them.\n"
            let listed: string = (
                $ambiguous | each {|a| $"// ($a.relation): ($a.cod | str join ', ')" } | str join "\n"
            )
            $"($header)($listed)"
        }
    )
    let schema_types: string = ($ts | get id | str join " + ")
    let schema_aspects: string = (
        if ($good | is-empty) { "none" } else { $good | get id | str join " + " }
    )
    let doms: string = (
        $good
        | each {|a| $"  ($a.id).dom = (identifier ($a.dom | first)) and ($a.id).cod = (identifier ($a.cod | first))" }
        | str join "\n"
    )

    $"#lang forge

// ($name) — generated from extracted entries by `olog frg`.
//
// Types and aspects only. A fact is a path equivalence and a flat list of
// entries states none, so any facts are yours to add.
open \"olog.frg\"

($type_lines)

($aspect_lines)($ambiguous_lines)

pred schema {
  Type = ($schema_types)
  Aspect = ($schema_aspects)
  no Fact

($doms)
}
"
}
