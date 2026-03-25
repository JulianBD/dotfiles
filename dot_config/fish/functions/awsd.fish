function awsd
    # Check if arguments were passed
    if test (count $argv) -eq 0
        # No arguments passed
        env AWS_PROFILE="$AWS_PROFILE" _awsd_prompt
    else
        # Arguments passed, assume profile name(s)
        env AWS_PROFILE="$AWS_PROFILE" _awsd_prompt $argv
    end

    # Ensure the awsd file exists
    touch ~/.awsd

    # Read the selected profile
    set selected_profile (cat ~/.awsd)

    if test -z "$selected_profile"
        # Unset AWS_PROFILE if empty
        set -e AWS_PROFILE
    else
        # Export AWS_PROFILE with the selected profile
        set -gx AWS_PROFILE "$selected_profile"
    end
end
