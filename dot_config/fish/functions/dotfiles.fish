function dotfiles --description "Dotfiles management via elvish modules"
    switch $argv[1]
        case theme
            if test (count $argv) -lt 2
                echo "Usage: dotfiles theme [apply|pick|list|sync|current]"
                return 1
            end
            switch $argv[2]
                case apply
                    if test (count $argv) -lt 3
                        echo "Usage: dotfiles theme apply <name>"
                        return 1
                    end
                    elvish -c "use dotfiles/theme; theme:apply $argv[3]"
                case pick
                    elvish -c 'use dotfiles/theme; theme:pick'
                case list
                    elvish -c 'use dotfiles/theme; theme:list'
                case sync
                    elvish -c 'use dotfiles/theme; theme:sync'
                case current
                    elvish -c 'use dotfiles/theme; theme:current'
                case '*'
                    echo "Unknown: dotfiles theme $argv[2]"
            end
        case '*'
            echo "Usage: dotfiles [theme]"
    end
end
