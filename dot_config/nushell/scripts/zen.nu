# opencode zen — a thin nushell client.
#
#   use zen.nu
#   zen models claude
#   zen chat "explain nushell closures in one sentence"
#   open notes.md | zen chat "summarize this" -m gpt-5.6-sol
#
# Zen speaks each model's *native* protocol rather than one unified API, so
# `chat` picks the endpoint from the model id:
#   claude-*             -> /v1/messages                    (anthropic, x-api-key)
#   gpt-* grok-* muse-*  -> /v1/responses                   (openai, bearer)
#   gemini-*             -> /v1/models/{id}:generateContent (google, x-goog-api-key)
#   everything else      -> /v1/chat/completions            (openai-compatible)
# Guessing wrong shows up as a 500 or "Input type not supported"; override with
# --protocol in that case.

const BASE = "https://opencode.ai/zen/v1"

# API key: $env.OPENCODE_ZEN_API_KEY wins, else the key opencode already stored.
export def key []: nothing -> string {
    if "OPENCODE_ZEN_API_KEY" in $env {
        return $env.OPENCODE_ZEN_API_KEY
    }
    let auth = ($env.HOME | path join ".local/share/opencode/auth.json")
    if not ($auth | path exists) {
        error make {msg: "no zen key: set $env.OPENCODE_ZEN_API_KEY or run `opencode auth login`"}
    }
    let k = (open $auth | get -o opencode.key)
    if ($k | is-empty) {
        error make {msg: $"no `opencode` provider key in ($auth)"}
    }
    $k
}

# Which wire protocol a model id speaks.
def protocol [model: string]: nothing -> string {
    if ($model | str starts-with "claude-") { "anthropic"
    } else if ($model | str starts-with "gpt-") or ($model | str starts-with "grok-") or ($model | str starts-with "muse-") { "openai-responses"
    } else if ($model | str starts-with "gemini-") { "google"
    } else { "openai-chat" }
}

def post [url: string, headers: record, body: record] {
    let resp = (
        http post --content-type application/json --headers $headers --allow-errors $url $body
    )
    let err = ($resp | get -o error)
    if $err != null {
        error make {msg: $"zen: ($err | get -o message | default ($err | to nuon))"}
    }
    $resp
}

# List the models zen currently serves.
export def models [
    pattern?: string  # optional regex filter on the model id
]: nothing -> table {
    let rows = (
        http get --headers {Authorization: $"Bearer (key)"} $"($BASE)/models"
        | get data
        | select id owned_by
    )
    if $pattern == null { $rows } else { $rows | where id =~ $pattern }
}

# Send a single-turn prompt. Piped input is appended as context.
export def chat [
    prompt: string                            # user message
    --model (-m): string = "claude-sonnet-5"  # any id from `zen models`
    --system (-s): string                     # system prompt
    --temperature (-t): float
    --max-tokens: int = 4096
    --protocol (-p): string                   # force anthropic|openai-responses|google|openai-chat
    --raw (-r)                                # return the whole response record
]: [nothing -> any, string -> any] {
    let piped = $in
    let content = if ($piped | is-empty) { $prompt } else { $"($prompt)\n\n---\n($piped)" }
    let temp = (if $temperature == null { {} } else { {temperature: $temperature} })
    let k = (key)

    match ($protocol | default (protocol $model)) {
        "anthropic" => {
            let body = (
                {model: $model, max_tokens: $max_tokens, messages: [{role: "user", content: $content}]}
                | merge (if $system == null { {} } else { {system: $system} })
                | merge $temp
            )
            let resp = (post $"($BASE)/messages" {"x-api-key": $k, "anthropic-version": "2023-06-01"} $body)
            if $raw { $resp } else {
                $resp.content | where type == "text" | get -o text | str join "\n"
            }
        }
        "openai-responses" => {
            let body = (
                {model: $model, input: $content, max_output_tokens: $max_tokens}
                | merge (if $system == null { {} } else { {instructions: $system} })
                | merge $temp
            )
            let resp = (post $"($BASE)/responses" {Authorization: $"Bearer ($k)"} $body)
            if $raw { $resp } else {
                $resp.output | where type == "message" | get content | flatten
                | where type == "output_text" | get -o text | str join "\n"
            }
        }
        "google" => {
            let body = (
                {contents: [{role: "user", parts: [{text: $content}]}]}
                | merge (if $system == null { {} } else {
                    {systemInstruction: {parts: [{text: $system}]}}
                  })
                | merge {generationConfig: ({maxOutputTokens: $max_tokens} | merge $temp)}
            )
            let resp = (post $"($BASE)/models/($model):generateContent" {"x-goog-api-key": $k} $body)
            if $raw { $resp } else {
                $resp.candidates.0.content.parts | where {|p| "text" in $p} | get text | str join "\n"
            }
        }
        _ => {
            let messages = (
                (if $system == null { [] } else { [{role: "system", content: $system}] })
                | append {role: "user", content: $content}
            )
            let body = ({model: $model, messages: $messages, max_tokens: $max_tokens} | merge $temp)
            let resp = (post $"($BASE)/chat/completions" {Authorization: $"Bearer ($k)"} $body)
            if $raw { $resp } else { $resp.choices.0.message.content }
        }
    }
}

# Token usage for one call — handy for comparing models. Shape is provider-native.
export def usage [
    prompt: string
    --model (-m): string = "claude-sonnet-5"
]: nothing -> record {
    let resp = (chat $prompt --model $model --raw)
    $resp | get -o usage | default ($resp | get -o usageMetadata) | default {}
}
