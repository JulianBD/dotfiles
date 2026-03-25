function ghostty-theme --description "Pick and apply a ghostty ef/modus/doric/standard theme"
    set config ~/.config/ghostty/config

    set themes (/Applications/Ghostty.app/Contents/MacOS/ghostty +list-themes 2>/dev/null \
        | t '/^(ef-|modus-|doric-|standard-)/s@0')

    if test (count $themes) -eq 0
        echo "No matching themes found"
        return 1
    end

    set chosen (printf '%s\n' $themes | peco --prompt "ghostty theme > ")
    test -z "$chosen"; and return 0

    t "r/^theme = .*/theme = $chosen/" $config > $config.tmp
    and mv $config.tmp $config


    echo "theme = $chosen"
    theme-apply
end
