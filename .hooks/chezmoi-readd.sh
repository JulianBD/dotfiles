#!/usr/bin/env bash
# Stop a commit that would leave deployed-file drift uncaptured.
#
# Default is to report and block, not to auto-add. Drift is repo-wide state
# with no relation to what you staged, so re-adding it silently folds unrelated
# edits into whatever commit you happen to be making. Set CHEZMOI_AUTO_READD=1
# to re-add and stage instead.
#
# Either way, a file that is drifted *and* staged is a real conflict — both
# sides changed, and `chezmoi re-add` copies target -> source, so it would
# discard your staged edit. Those always block.
#
# Templates need no guard: `chezmoi re-add` refuses to overwrite them.
set -euo pipefail

command -v chezmoi >/dev/null 2>&1 || exit 0

# Column 1 of `chezmoi status` is last-written-vs-actual: it is M only when the
# deployed file was edited out of band, which is exactly the drift worth
# capturing. Keying on column 2 instead would also catch files whose source
# moved ahead of a stale target -- those need `chezmoi apply`, not a re-add.
drifted=$(chezmoi status | awk '/^M/ { print substr($0, 4) }')
[ -n "$drifted" ] || exit 0

staged=$(git diff --cached --name-only --diff-filter=ACM)
repo_root=$(git rev-parse --show-toplevel)

conflicts=()
clean=()
for target in $drifted; do
    abs_target="$HOME/$target"
    # Source entries never applied to this machine have no file to re-add.
    [ -f "$abs_target" ] || continue

    src=$(chezmoi source-path "$abs_target" 2>/dev/null) || continue
    rel_src=${src#"$repo_root"/}

    if grep -qxF "$rel_src" <<<"$staged"; then
        conflicts+=("$target")
    else
        clean+=("$abs_target")
    fi
done

if [ ${#conflicts[@]} -gt 0 ]; then
    echo "chezmoi: changed on BOTH sides — source staged, deployed copy drifted." >&2
    echo "Re-adding would discard your staged edit:" >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    echo >&2
    echo "  chezmoi diff <target>     # compare the two" >&2
    echo "  chezmoi apply <target>    # source wins" >&2
    echo "  chezmoi re-add <target>   # deployed copy wins" >&2
    exit 1
fi

[ ${#clean[@]} -gt 0 ] || exit 0

if [ "${CHEZMOI_AUTO_READD:-0}" != "1" ]; then
    echo "chezmoi: these deployed files drifted from source:" >&2
    printf '  %s\n' "${clean[@]#"$HOME"/}" >&2
    echo >&2
    echo "Capture what belongs in this commit, then commit again:" >&2
    echo "  chezmoi re-add <target>...   # then git add the source paths" >&2
    echo "Or re-add everything: CHEZMOI_AUTO_READD=1 git commit ..." >&2
    exit 1
fi

chezmoi re-add "${clean[@]}"
for target in "${clean[@]}"; do
    src=$(chezmoi source-path "$target")
    # A template is a no-op for re-add; don't stage a file that didn't change.
    git diff --quiet -- "$src" || { git add -- "$src"; echo "chezmoi: re-added ${target#"$HOME"/}"; }
done
