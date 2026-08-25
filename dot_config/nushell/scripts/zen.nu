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

use ./http.nu

const BASE = "https://opencode.ai/zen/v1"

# Resolve the zen API key.
#
# $env.OPENCODE_ZEN_API_KEY wins, else the key opencode already stored.
export def key []: nothing -> string {
    let from_environment = (http env-key "OPENCODE_ZEN_API_KEY")
    if $from_environment != null {
        return $from_environment
    }
    let auth = ($env.HOME | path join ".local/share/opencode/auth.json")
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
def protocol [
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
]: nothing -> table {
    let rows = (
        http get-json $"($BASE)/models" --headers {Authorization: $"Bearer (key)"} --label "zen"
        | get data
        | select id owned_by
    )
    if $pattern == null { $rows } else { $rows | where id =~ $pattern }
}

# Send a single-turn prompt to a zen model.
#
# Piped input is appended to the prompt as context, under a `---` separator.
export def chat [
    prompt: string                            # User message
    --model (-m): string = "claude-sonnet-5"  # Any id from `zen models`
    --system (-s): string                     # System prompt
    --temperature (-t): float                 # Sampling temperature
    --max-tokens: int = 4096                  # Response length cap
    --protocol (-p): string                   # Force anthropic|openai-responses|google|openai-chat
    --raw (-r)                                # Return the whole response record
]: [nothing -> any, string -> any] {
    let piped = $in
    let content = if ($piped | is-empty) { $prompt } else { $"($prompt)\n\n---\n($piped)" }
    let sampling = if $temperature == null { {} } else { {temperature: $temperature} }
    let api_key = (key)

    match ($protocol | default (protocol $model)) {
        "anthropic" => {
            let body = (
                {
                    model: $model,
                    max_tokens: $max_tokens,
                    messages: [{role: "user", content: $content}]
                }
                | merge (if $system == null { {} } else { {system: $system} })
                | merge $sampling
            )
            let headers = {"x-api-key": $api_key, "anthropic-version": "2023-06-01"}
            let response = (http post-json $"($BASE)/messages" $body --headers $headers --label "zen")
            if $raw { $response } else {
                $response.content | where type == "text" | get -o text | str join "\n"
            }
        }
        "openai-responses" => {
            let body = (
                {model: $model, input: $content, max_output_tokens: $max_tokens}
                | merge (if $system == null { {} } else { {instructions: $system} })
                | merge $sampling
            )
            let headers = {Authorization: $"Bearer ($api_key)"}
            let response = (http post-json $"($BASE)/responses" $body --headers $headers --label "zen")
            if $raw { $response } else {
                $response.output
                | where type == "message"
                | get content
                | flatten
                | where type == "output_text"
                | get -o text
                | str join "\n"
            }
        }
        "google" => {
            let body = (
                {
                    contents: [
                        {role: "user", parts: [{text: $content}]}
                    ]
                }
                | merge (
                    if $system == null { {} } else {
                        {systemInstruction: {parts: [{text: $system}]}}
                    }
                )
                | merge {generationConfig: ({maxOutputTokens: $max_tokens} | merge $sampling)}
            )
            let headers = {"x-goog-api-key": $api_key}
            let url = $"($BASE)/models/($model):generateContent"
            let response = (http post-json $url $body --headers $headers --label "zen")
            if $raw { $response } else {
                $response.candidates.0.content.parts
                | where {|part| "text" in $part }
                | get text
                | str join "\n"
            }
        }
        _ => {
            let messages = (
                (if $system == null { [] } else { [{role: "system", content: $system}] })
                | append {role: "user", content: $content}
            )
            let body = ({model: $model, messages: $messages, max_tokens: $max_tokens} | merge $sampling)
            let headers = {Authorization: $"Bearer ($api_key)"}
            let response = (http post-json $"($BASE)/chat/completions" $body --headers $headers --label "zen")
            if $raw { $response } else { $response.choices.0.message.content }
        }
    }
}

# Token usage for one call, handy for comparing models.
#
# The record shape is provider-native.
export def usage [
    prompt: string                            # User message
    --model (-m): string = "claude-sonnet-5"  # Any id from `zen models`
]: nothing -> record {
    let response = (chat $prompt --model $model --raw)
    $response | get -o usage | default ($response | get -o usageMetadata) | default {}
}
