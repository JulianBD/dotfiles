# Completions for the theme CLI
complete -c theme -f

# Subcommands (no subcommand yet)
complete -c theme -n "not __fish_seen_subcommand_from apply pick list current sync" \
    -a "apply pick list current sync"

# Theme names for "theme apply"
complete -c theme -n "__fish_seen_subcommand_from apply" \
    -a "(theme list 2>/dev/null | string trim | string replace -r '\\s+.*' '')"
