# opencode zen — a thin nushell client.
#
#   use zen.nu
#   zen models claude
#   zen chat "explain nushell closures in one sentence"
#   open notes.md | zen chat "summarize this" -m gpt-5.6-sol
#   zen chat raw "hi" -m kimi-k3        # whole response record
#   zen cmd "every m4a here to wav"     # one command, ready to run
#   zen chat "hi" --session work        # continue a stored conversation
#   store history | last 5              # every call, one-off or not
#
# Zen speaks each model's *native* protocol rather than one unified API, so
# the endpoint is picked from the model id:
#   claude-*             -> /v1/messages                    (anthropic, x-api-key)
#   gpt-* grok-* muse-*  -> /v1/responses                   (openai, bearer)
#   gemini-*             -> /v1/models/{id}:generateContent (google, x-goog-api-key)
#   everything else      -> /v1/chat/completions            (openai-compatible)
# Guessing wrong shows up as a 500 or "Input type not supported"; override with
# --protocol in that case.

use ./http.nu
use ./store.nu

const BASE = "https://opencode.ai/zen/v1"

# The wire protocols this module knows how to speak.
const PROTOCOLS = ["anthropic" "openai-responses" "google" "openai-chat"]

# Shells `zen cmd` knows how to target.
const SHELLS = ["nu" "bash" "fish" "zsh"]

# Completer for --shell.
def shell-names []: nothing -> list<string> {
    $SHELLS
}

# Completer and validation source for --protocol.
def protocol-names []: nothing -> list<string> {
    $PROTOCOLS
}

# Completer for --session: the sessions already on disk.
def session-names []: nothing -> list<string> {
    try { store sessions | get name } catch { [] }
}

# Completer for --model: the live catalogue, empty when unreachable.
#
# Tab completion must never raise, so a missing key or offline host yields no
# suggestions rather than an error.
def model-names []: nothing -> list<string> {
    try { models | get id } catch { [] }
}

# Resolve the zen API key.
#
# $env.OPENCODE_ZEN_API_KEY wins, else the key opencode already stored.
export def key []: nothing -> string {
    let from_environment = (http env-key "OPENCODE_ZEN_API_KEY")
    if $from_environment != null {
        return $from_environment
    }
    let auth: string = ($env.HOME | path join ".local/share/opencode/auth.json")
    if not ($auth | path exists) {
        error make {msg: "no zen key: set $env.OPENCODE_ZEN_API_KEY or run `opencode auth login`"}
    }
    let stored = (open $auth | get -o opencode.key)
    if ($stored | is-empty) {
        error make {msg: $"no `opencode` provider key in ($auth)"}
    }
    $stored
}

# Which wire protocol a model id speaks.
def protocol-for [
    model: string  # Model id, e.g. claude-sonnet-5
]: nothing -> string {
    if ($model | str starts-with "claude-") { "anthropic"
    } else if ($model | str starts-with "gpt-") or ($model | str starts-with "grok-") or ($model | str starts-with "muse-") { "openai-responses"
    } else if ($model | str starts-with "gemini-") { "google"
    } else { "openai-chat" }
}

# List the models zen currently serves.
export def models [
    pattern?: string  # Regex filter on the model id
]: nothing -> table<id: string, owned_by: string> {
    let rows: table<id: string, owned_by: string> = (
        http get-json $"($BASE)/models" --headers {Authorization: $"Bearer (key)"} --label "zen"
        | get data
        | select id owned_by
    )
    if $pattern == null { $rows } else { $rows | where id =~ $pattern }
}

# Build the provider-native request body from normalized turns.
#
# Turns arrive as `{role, content}` with roles "user" and "assistant", which is
# the shape sessions are stored in. Each branch below renders that one shape
# into its provider's wire format — anthropic takes it nearly as-is, google
# renames the assistant role to "model" and wraps content in parts, and the
# chat-completions branch prepends the system prompt as a message rather than
# passing it beside them. Storing normalized and rendering here is what lets a
# session begin against one model and continue against another.
def body-for [
    protocol: string           # One of $PROTOCOLS
    model: string              # Model id
    turns: list<record>        # Normalized turns: {role, content}
    max_tokens: int            # Response length cap
    --system: any              # System prompt, or null
    --temperature: any         # Sampling temperature, or null
]: nothing -> record {
    let sampling: record = if $temperature == null { {} } else { {temperature: $temperature} }

    match $protocol {
        "anthropic" => {
            {
                model: $model,
                max_tokens: $max_tokens,
                messages: $turns
            }
            | merge (if $system == null { {} } else { {system: $system} })
            | merge $sampling
        }
        "openai-responses" => {
            {model: $model, input: $turns, max_output_tokens: $max_tokens}
            | merge (if $system == null { {} } else { {instructions: $system} })
            | merge $sampling
        }
        "google" => {
            {
                contents: (
                    $turns | each {|turn|
                        {
                            role: (if $turn.role == "assistant" { "model" } else { $turn.role }),
                            parts: [{text: $turn.content}]
                        }
                    }
                )
            }
            | merge (
                if $system == null { {} } else {
                    {systemInstruction: {parts: [{text: $system}]}}
                }
            )
            | merge {generationConfig: ({maxOutputTokens: $max_tokens} | merge $sampling)}
        }
        _ => {
            let messages: list<record> = (
                (if $system == null { [] } else { [{role: "system", content: $system}] })
                | append $turns
            )
            {model: $model, messages: $messages, max_tokens: $max_tokens} | merge $sampling
        }
    }
}

# Route one request to the endpoint and headers its protocol requires.
def send [
    protocol: string  # One of $PROTOCOLS
    model: string     # Model id
    body: record      # Provider-native request body
]: nothing -> record {
    let api_key: string = (key)

    match $protocol {
        "anthropic" => {
            let headers = {"x-api-key": $api_key, "anthropic-version": "2023-06-01"}
            http post-json $"($BASE)/messages" $body --headers $headers --label "zen"
        }
        "openai-responses" => {
            let headers = {Authorization: $"Bearer ($api_key)"}
            http post-json $"($BASE)/responses" $body --headers $headers --label "zen"
        }
        "google" => {
            let headers = {"x-goog-api-key": $api_key}
            http post-json $"($BASE)/models/($model):generateContent" $body --headers $headers --label "zen"
        }
        _ => {
            let headers = {Authorization: $"Bearer ($api_key)"}
            http post-json $"($BASE)/chat/completions" $body --headers $headers --label "zen"
        }
    }
}

# Pull the assistant text out of a provider-native response.
def text-of [
    protocol: string  # One of $PROTOCOLS
    response: record  # Whole response record
]: nothing -> string {
    match $protocol {
        "anthropic" => {
            $response.content | where type == "text" | get -o text | str join "\n"
        }
        "openai-responses" => {
            $response.output
            | where type == "message"
            | get content
            | flatten
            | where type == "output_text"
            | get -o text
            | str join "\n"
        }
        "google" => {
            $response.candidates.0.content.parts
            | where {|part| "text" in $part }
            | get text
            | str join "\n"
        }
        _ => { $response.choices.0.message.content }
    }
}

# Token usage out of a response, whatever the provider called the field.
def usage-of [
    response: record  # Provider-native response
]: nothing -> record {
    $response | get -o usage | default ($response | get -o usageMetadata) | default {}
}

# Record a completed call, and extend the session ledger when there is one.
#
# History is written for every call including one-offs; the session file only
# when one was named. Nothing reads history back into a request, so logging a
# one-off records it without making any later call depend on it.
def remember [
    kind: string      # Which shape of request this was
    model: string     # Model id
    session: any      # Session name, or null
    prompt: string    # What was asked
    reply: string     # What came back
    response: record  # Provider-native response, for usage
]: nothing -> nothing {
    store history append {
        model: $model,
        kind: $kind,
        session: $session,
        prompt: $prompt,
        reply: $reply,
        usage: (usage-of $response)
    }
    if $session != null {
        store session append $session [
            {role: "user", content: $prompt}
            {role: "assistant", content: $reply}
        ]
    }
}

# Resolve which session a call belongs to, if any.
def resolve-session [
    name: any   # Explicit --session value, or null
    resume: bool  # Whether --resume was given
]: nothing -> any {
    if $name != null { return $name }
    if not $resume { return null }
    let recent: list<string> = (store sessions | get name)
    if ($recent | is-empty) {
        error make {msg: "no sessions yet; start one with --session <name>"}
    }
    $recent | first
}

# Resolve and validate the protocol for a request.
def resolve-protocol [
    model: string  # Model id
    override: any  # Explicit --protocol value, or null
]: nothing -> string {
    if $override == null {
        return (protocol-for $model)
    }
    if $override not-in $PROTOCOLS {
        error make {msg: $"unknown protocol ($override); expected one of ($PROTOCOLS | str join ', ')"}
    }
    $override
}

# Perform one request, returning the whole provider-native response.
#
# Optional values arrive as `any` because nushell has no optional type: a
# typed parameter rejects the null that an unset flag carries. Public commands
# below keep precise types and funnel through here.
def request [
    prompt: string    # User message
    piped: any        # Piped context, or null
    model: string     # Model id
    system: any       # System prompt, or null
    temperature: any  # Sampling temperature, or null
    max_tokens: int   # Response length cap
    protocol: any     # Forced wire protocol, or null
    history: any      # Prior normalized turns, or null
]: nothing -> record {
    let content: string = if ($piped | is-empty) {
        $prompt
    } else {
        $"($prompt)\n\n---\n($piped)"
    }
    let turns: list<record> = (
        ($history | default []) | append {role: "user", content: $content}
    )
    let wire: string = (resolve-protocol $model $protocol)
    let body: record = (
        body-for $wire $model $turns $max_tokens --system $system --temperature $temperature
    )
    send $wire $model $body
}

# Send a single-turn prompt and return the whole response record.
#
# Piped input is appended to the prompt as context, under a `---` separator.
export def "chat raw" [
    prompt: string                                        # User message
    --model (-m): string@model-names = "claude-sonnet-5"  # Any id from `zen models`
    --system (-s): string                                 # System prompt
    --temperature (-t): float                             # Sampling temperature
    --max-tokens: int = 4096                              # Response length cap
    --protocol (-p): string@protocol-names                # Force a wire protocol
]: [nothing -> record, string -> record] {
    request $prompt $in $model $system $temperature $max_tokens $protocol null
}

# Send a prompt and return the assistant's text.
#
# One-off by default: nothing from an earlier call is sent, and nothing this
# call writes will be sent later. `--session` opts into a conversation, loading
# that session's turns as context and appending this exchange to it.
#
# Either way the call is logged to history, which is never replayed.
#
# Piped input is appended to the prompt as context, under a `---` separator.
export def chat [
    prompt: string                                        # User message
    --model (-m): string@model-names = "claude-sonnet-5"  # Any id from `zen models`
    --system (-s): string                                 # System prompt
    --temperature (-t): float                             # Sampling temperature
    --max-tokens: int = 4096                              # Response length cap
    --protocol (-p): string@protocol-names                # Force a wire protocol
    --session: string@session-names                       # Continue this named session
    --resume (-r)                                         # Continue the most recent session
]: [nothing -> string, string -> string] {
    let piped: any = $in
    let name: any = (resolve-session $session $resume)
    let prior: list<record> = if $name == null { [] } else { store session load $name }

    let response: record = (
        request $prompt $piped $model $system $temperature $max_tokens $protocol $prior
    )
    let reply: string = (text-of (resolve-protocol $model $protocol) $response)
    remember "chat" $model $name $prompt $reply $response
    $reply
}

# Token usage for one call, handy for comparing models.
#
# The record shape is provider-native.
export def usage [
    prompt: string                                        # User message
    --model (-m): string@model-names = "claude-sonnet-5"  # Any id from `zen models`
]: nothing -> record {
    let response: record = (request $prompt null $model null null 4096 null null)
    usage-of $response
}

# Strip the packaging a model puts around a command.
#
# Code fences, a leading `$` prompt marker and surrounding blank lines all show
# up even when the system prompt forbids them, so this is belt and braces
# rather than a substitute for asking.
def unfence []: string -> string {
    $in
    | lines
    | where {|line| not ($line | str trim | str starts-with "```") }
    | str join "\n"
    | str trim
    | str replace -r '^\$\s+' ''
}

# Ask for a single command line and get it back bare, ready to inspect and run.
#
# One-off by design: refining a command is better served by editing it than by
# a conversation, so `cmd` takes no --session. It is still logged to history,
# which is what makes "what was that incantation last week" answerable.
#
# Nothing is executed here — the point is that you read it first. The Ctrl-G
# keybinding in the autoload feeds the current prompt buffer through this and
# replaces the buffer with the result, leaving the Enter to you.
#
# Piped input is passed along as context:
#   ls | zen cmd "delete the ones older than a year"
export def cmd [
    request: string                                       # What you want, in English
    --model (-m): string@model-names = "claude-sonnet-5"  # Any id from `zen models`
    --shell: string@shell-names = "bash"                  # Shell to target
]: [nothing -> string, string -> string] {
    let context: any = $in
    let system: string = $"You turn a request into exactly one ($shell) command line.

Reply with the command and nothing else. No explanation, no commentary, no
markdown, no code fences, no leading prompt marker. If the task needs several
steps, join them into a single line using the shell's own syntax.

Prefer widely available tools. Prefer options that are safe to run twice.
Never invent flags; if you are unsure a flag exists, use a simpler form."

    # 2000, not a few hundred: reasoning models spend the budget before
    # emitting anything, and kimi-k3 has been seen using 353 reasoning tokens
    # on a one-line request. Too small a cap finishes with reason "length" and
    # nothing usable in the message.
    let response: record = (request $request $context $model $system null 2000 null null)
    let suggestion: string = (
        text-of (resolve-protocol $model null) $response | unfence
    )
    remember "cmd" $model null $request $suggestion $response
    $suggestion
}

# The shape a proposed command comes back in.
const PROPOSAL_SCHEMA = {
    type: "object",
    properties: {
        shell: {type: "string", enum: ["bash" "nu" "fish" "zsh"]},
        command: {type: "string"},
        destructive: {type: "boolean"}
    },
    required: ["shell" "command" "destructive"],
    additionalProperties: false
}

# Ask for a command as structured data rather than as text.
#
# Returns {shell, command, destructive}, so the caller can dispatch on the
# shell instead of guessing, and can gate on `destructive` before running
# anything. Nothing is executed here.
#
# This uses `response_format: json_schema`, which is a chat-completions
# feature. Anthropic expresses the same idea through a forced tool call and
# google through `responseSchema`, so unlike `chat` this does not work across
# every protocol; the model must be one that zen routes to /chat/completions.
#
# Note on --max-tokens: reasoning models spend the budget before emitting
# anything. kimi-k3 used 353 reasoning tokens on a one-line request, so a cap
# that looks generous for the output alone will truncate to a `length` finish
# with nothing usable in it.
export def propose [
    request: string                                  # What you want, in English
    --model (-m): string@model-names = "kimi-k3"     # Must route to openai-chat
    --max-tokens: int = 2000                         # Includes reasoning tokens
]: [nothing -> record, string -> record] {
    let context: any = $in
    let wire: string = (protocol-for $model)
    if $wire != "openai-chat" {
        error make {
            msg: $"propose needs a chat-completions model; ($model) speaks ($wire)"
        }
    }

    let content: string = if ($context | is-empty) {
        $request
    } else {
        $"($request)\n\n---\n($context)"
    }
    let body: record = {
        model: $model,
        max_tokens: $max_tokens,
        messages: [{role: "user", content: $content}],
        response_format: {
            type: "json_schema",
            json_schema: {name: "proposal", strict: true, schema: $PROPOSAL_SCHEMA}
        }
    }

    let response: record = (send $wire $model $body)
    let raw: string = (text-of $wire $response)
    let proposal: record = ($raw | from json)
    remember "propose" $model null $request $raw $response
    $proposal
}
