function theme-apply --description "Apply current ghostty theme to all downstream configs (sketchybar, wallpaper)"
    set ghostty /Applications/Ghostty.app/Contents/MacOS/ghostty

    if not test -x $ghostty
        echo "Ghostty not found, skipping theme apply"
        return 1
    end

    set raw ($ghostty +show-config 2>/dev/null | rg "^(background|foreground|palette)")

    if test (count $raw) -eq 0
        echo "Could not read ghostty colors"
        return 1
    end

    set bg (printf '%s\n' $raw | rg "^background" | t 'm/[0-9a-f]{6}/@0')

    # --- Sketchybar colors ---
    sketchybar-colors
    or echo "Warning: sketchybar-colors failed"

    # --- Wallpaper generation ---
    if command -q magick; and command -q m
        set wallpaper_dir "$HOME/.local/share/wallpapers"
        mkdir -p $wallpaper_dir

        # Get resolution for each connected display
        set displays (m display --status | rg "Resolution:" | t 'm/(\d+) x (\d+)/' | t 'r/ x /x/')

        if test (count $displays) -eq 0
            echo "Warning: could not detect display resolution"
        else
            set idx 0
            for res in $displays
                set w (string split x $res)[1]
                set h (string split x $res)[2]
                set wallpaper "$wallpaper_dir/wallpaper-$idx.jpg"
                magick -size {$w}x{$h} "xc:#$bg" -quality 95 $wallpaper
                echo "Generated wallpaper: "$w"x"$h" #$bg → $wallpaper"
                set idx (math $idx + 1)
            end

            # Set wallpaper (first display's wallpaper)
            if test -f "$wallpaper_dir/wallpaper-0.jpg"
                m wallpaper --set "$wallpaper_dir/wallpaper-0.jpg"
                echo "Wallpaper set to #$bg"
            end
        end
    else
        echo "Warning: magick or m-cli not installed, skipping wallpaper"
    end
end
