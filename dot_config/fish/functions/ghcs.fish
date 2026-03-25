function ghcs
    set -l FUNCNAME ghcs
    set -l TARGET shell
    set -l GH_DEBUG $GH_DEBUG
    set -l GH_HOST $GH_HOST

    set -l __USAGE "
Wrapper around \`gh copilot suggest\` to suggest a command based on a natural language description of the desired output effort.
Supports executing suggested commands if applicable.

USAGE
  ghcs [flags] <prompt>

FLAGS
  -d, --debug           Enable debugging
  -h, --help            Display help usage
      --hostname        The GitHub host to use for authentication
  -t, --target target   Target for suggestion; must be shell, gh, git
                       default: \"$TARGET\"

EXAMPLES

- Guided experience
  ghcs

- Git use cases
  ghcs -t git \"Undo the most recent local commits\"
  ghcs -t git \"Clean up local branches\"
  ghcs -t git \"Setup LFS for images\"

- Working with the GitHub CLI in the terminal
  ghcs -t gh \"Create pull request\"
  ghcs -t gh \"List pull requests waiting for my review\"
  ghcs -t gh \"Summarize work I have done in issues and pull requests for promotion\"

- General use cases
  ghcs \"Kill processes holding onto deleted files\"
  ghcs \"Test whether there are SSL/TLS issues with github.com\"
  ghcs \"Convert SVG to PNG and resize\"
  ghcs \"Convert MOV to animated PNG\"
"

    # Argument parsing
    set -l args
    set -l i 1
    while test $i -le (count $argv)
        set arg $argv[$i]
        switch $arg
            case -d --debug
                set GH_DEBUG api
            case -h --help
                echo "$__USAGE"
                return 0
            case --hostname
                set i (math $i + 1)
                set GH_HOST $argv[$i]
            case -t --target
                set i (math $i + 1)
                set TARGET $argv[$i]
            case '*'
                set args $args $arg
        end
        set i (math $i + 1)
    end

    set -l TMPFILE (mktemp -t gh-copilotXXXXXX)
    function __cleanup --on-event fish_exit
        rm -f $TMPFILE
    end

    if env GH_DEBUG=$GH_DEBUG GH_HOST=$GH_HOST gh copilot suggest -t $TARGET $args --shell-out $TMPFILE
        if test -s $TMPFILE
            set FIXED_CMD (cat $TMPFILE)
            commandline -r -- $FIXED_CMD
            echo
            eval $FIXED_CMD
        end
    else
        return 1
    end
end
