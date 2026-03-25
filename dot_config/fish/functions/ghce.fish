function ghce
    set -l FUNCNAME ghce
    set -l GH_DEBUG $GH_DEBUG
    set -l GH_HOST $GH_HOST

    set -l __USAGE "
Wrapper around \`gh copilot explain\` to explain a given input command in natural language.

USAGE
  $FUNCNAME [flags] <command>

FLAGS
  -d, --debug      Enable debugging
  -h, --help       Display help usage
      --hostname   The GitHub host to use for authentication

EXAMPLES

# View disk usage, sorted by size
  {FUNCNAME} 'du -sh | sort -h'

# View git repository history as text graphical representation
  {FUNCNAME} 'git log --oneline --graph --decorate --all'

# Remove binary objects larger than 50 megabytes from git history
  {FUNCNAME} 'bfg --strip-blobs-bigger-than 50M'
"
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
            case '*'
                set args $args $arg
        end
        set i (math $i + 1)
    end

    env GH_DEBUG=$GH_DEBUG GH_HOST=$GH_HOST gh copilot explain $args
end
