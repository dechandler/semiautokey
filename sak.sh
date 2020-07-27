#!/usr/bin/env bash

# basically all borrowed from pass and passmenu

shopt -s nullglob globstar

CLIP_TIME="${SAK_CLIP_TIME:-45}"

PREFIX=${AUTOKEY_DATA_DIR-~/.config/autokey/data}


typeit=0
if [[ $1 == "--type" ]]; then
    typeit=1
    shift
fi



clip() {
        # This base64 business is because bash cannot store binary data in a shell
        # variable. Specifically, it cannot store nulls nor (non-trivally) store
        # trailing new lines.
        local txt_file="$1"
        local sleep_argv0="semiautokey sleep on display $DISPLAY"
        pkill -f "^$sleep_argv0" 2>/dev/null && sleep 0.5
        local before="$(xclip -o -selection clipboard 2>/dev/null | base64)"
        xclip -selection clipboard < "$txt_file" || die "Error: Could not copy data to the clipboard"
        (
                ( exec -a "$sleep_argv0" bash <<<"trap 'kill %1' TERM; sleep '$CLIP_TIME' & wait" )
                local now="$(xclip -o -selection clipboard | base64)"
                [[ $now != $(base64 "$txt_file") ]] && before="$now"

                echo "$before" | base64 -d | xclip -selection clipboard
        ) >/dev/null 2>&1 & disown
}



txt_files=( "$PREFIX"/**/*.txt )
txt_files=( "${txt_files[@]#"$PREFIX"/}" )
txt_files=( "${txt_files[@]%.txt}" )

selection=$(printf '%s\n' "${txt_files[@]}" | ${DMENU-dmenu} "$@")
[[ -n $selection ]] || exit

txt_file="${PREFIX}/${selection}.txt"


if [[ $typeit -eq 0 ]]; then
    clip "$txt_file"
else
    xdotool type --clearmodifiers --file "$txt_file"
fi
