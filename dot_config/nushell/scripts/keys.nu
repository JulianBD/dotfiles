# Keybinding handlers — the reedline half of the zen tooling.
#
# Each of these is bound to a key in config.nu. They share one shape: read the
# prompt buffer or the last command, ask a model something about it, and put
# the answer where you can see it. None of them execute anything; the ones that
# produce a command rewrite the buffer and leave the Enter to you.
#
#   Ctrl-G  keys suggest   English in the buffer -> a command in the buffer
#   Alt-G   keys explain   a command in the buffer -> prose above the prompt
#   Alt-F   keys fix       the last command that failed -> a corrected one
#
# Handlers are separated from the bindings so they can be called by hand too,
# which is also how they get tested.

use ./zen.nu

# Model used by the keybindings, defaulting to whatever zen.nu defaults to.
# $ZEN_KEYS_MODEL overrides, which is the knob to reach for if the prompt feels
# slow — these calls block the prompt until they return.
#
# One model for both prose and proposals. An earlier version split them,
# on the theory that a non-reasoning model could not leak its scratchpad into
# an explanation. That theory was wrong: kimi-k2.6 reports reasoning tokens
# too (186 against k3's 165 on the same prompt), so the split bought nothing
# the schema does not already buy for `propose`.
def keys-model []: nothing -> string {
    $env.ZEN_KEYS_MODEL? | default (zen default-model)
}

# Render a proposal as something runnable from a nushell prompt.
#
# A nu command is returned as-is. Anything else is wrapped in its own
# interpreter, because bash syntax pasted bare into a nu prompt is a syntax
# error rather than a command.
#
# The wrapper uses a nushell *raw string* — r#'...'# — rather than ordinary
# quotes. The obvious approach is bash's close-escape-reopen dance,
# 'it'\''s', but that string is being typed into nu, not bash, and nu does not
# honour backslash escapes inside single quotes: it parses as three fragments
# and the result is malformed. A raw string takes the text literally, so an
# apostrophe needs no treatment at all. The hash count grows if the command
# would otherwise close the delimiter early.
export def wrap [
    proposal: record  # {shell, command}
]: nothing -> string {
    if $proposal.shell == "nu" { return $proposal.command }

    let fence: string = (
        ["#" "##" "###"]
        | where {|h| not ($proposal.command | str contains $"'($h)") }
        | first
    )
    $"($proposal.shell) -c r($fence)'($proposal.command)'($fence)"
}

# Show that something is happening, since the call blocks the prompt.
def working [
    what: string  # Short label
]: nothing -> nothing {
    print --no-newline $"\r($what)..."
}

# Clear the working line so it does not linger above the prompt.
def done []: nothing -> nothing {
    print --no-newline "\r\u{1b}[2K"
}

# Ctrl-G — turn the prompt buffer into a command you can run.
#
# The buffer is replaced, not executed: `commandline edit -r` deliberately
# omits `--accept`, so you read the result and decide.
export def suggest []: nothing -> nothing {
    let request: string = (commandline | str trim)
    if ($request | is-empty) { return }

    working "asking"
    let proposal: record = try {
        zen propose $request --model (keys-model)
    } catch {|err|
        done
        print $"zen: ($err.msg | lines | first)"
        return
    }
    done

    if ($proposal.command | is-empty) { return }
    if $proposal.destructive {
        print $"(ansi yellow)destructive — read it before you run it(ansi reset)"
    }
    commandline edit -r (wrap $proposal)
}

# Alt-G — explain whatever is in the buffer, without touching it.
#
# Prints above the prompt and leaves the buffer alone, so it is safe to press
# on a command you are part-way through composing.
export def explain []: nothing -> nothing {
    let subject: string = (commandline | str trim)
    if ($subject | is-empty) { return }

    working "reading"
    let answer: string = try {
        zen chat $subject --model (keys-model) --max-tokens 500 --system "You explain shell commands.

Given a command, say what it does in at most four short lines. Name each flag
that is doing real work. Call out anything destructive, irreversible, or
surprising first and plainly. No preamble, no restating the command."
    } catch {|err|
        done
        print $"zen: ($err.msg | lines | first)"
        return
    }
    done

    print $answer
}

# Alt-F — take the last command and propose a corrected one.
#
# History here is the plaintext log, which records no exit status, so the only
# signal beyond the command text is $env.LAST_EXIT_CODE, and stderr is not
# captured at all. That makes this a guess from the command alone; it is useful
# for typos and wrong flags, and weak on anything that failed for a reason only
# the error message would reveal.
export def fix []: nothing -> nothing {
    let previous: string = (history | last 1 | get -o command.0 | default "" | str trim)
    if ($previous | is-empty) {
        print "no previous command"
        return
    }

    let status: int = ($env.LAST_EXIT_CODE? | default 0)
    working "fixing"
    let proposal: record = try {
        zen propose $"This command failed with exit code ($status). Give a corrected version.

($previous)" --model (keys-model)
    } catch {|err|
        done
        print $"zen: ($err.msg | lines | first)"
        return
    }
    done

    if ($proposal.command | is-empty) { return }
    print $"was: ($previous)"
    if $proposal.destructive {
        print $"(ansi yellow)destructive — read it before you run it(ansi reset)"
    }
    commandline edit -r (wrap $proposal)
}
