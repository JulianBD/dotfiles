function just
    # Check if first argument is -u
    if test "$argv[1]" = -u
        # Remove -u from arguments and call user justfile
        set -e argv[1]
        command just --justfile ~/.user.justfile --working-directory . $argv
    else
        # Normal just command
        command just $argv
    end
end
