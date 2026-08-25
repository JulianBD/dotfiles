function m4a2wav
    set -l FUNCNAME m4a2wav

    set -l __USAGE "
Convert one or more .m4a files to .wav via ffmpeg.

Sample rate and channel count are inherited from the source, so the
decode is lossless relative to the already-lossy m4a. Output lands
next to the input unless -o is given.

USAGE
  $FUNCNAME [flags] <file.m4a>...

FLAGS
  -o, --outdir <dir>   Write .wav files to <dir> instead of alongside the input
  -f, --force          Overwrite existing .wav files
  -h, --help           Display help usage
"

    argparse -n $FUNCNAME h/help f/force 'o/outdir=' -- $argv
    or return 1

    if set -q _flag_help
        echo "$__USAGE"
        return 0
    end

    if test (count $argv) -eq 0
        echo "$__USAGE" >&2
        return 1
    end

    if not type -q ffmpeg
        echo "$FUNCNAME: ffmpeg not found on PATH" >&2
        return 1
    end

    if set -q _flag_outdir; and not test -d "$_flag_outdir"
        echo "$FUNCNAME: no such directory: $_flag_outdir" >&2
        return 1
    end

    set -l status_code 0

    for input in $argv
        if not test -f "$input"
            echo "$FUNCNAME: no such file: $input" >&2
            set status_code 1
            continue
        end

        set -l stem (string replace -r '\.[^./]*$' '' -- (basename "$input"))
        set -l output
        if set -q _flag_outdir
            set output "$_flag_outdir/$stem.wav"
        else
            set output (dirname "$input")"/$stem.wav"
        end

        if test -e "$output"; and not set -q _flag_force
            echo "$FUNCNAME: $output exists (use --force to overwrite)" >&2
            set status_code 1
            continue
        end

        if not ffmpeg -hide_banner -loglevel error -y -i "$input" -c:a pcm_s16le "$output"
            echo "$FUNCNAME: ffmpeg failed on $input" >&2
            set status_code 1
            continue
        end

        echo "$output"
    end

    return $status_code
end
