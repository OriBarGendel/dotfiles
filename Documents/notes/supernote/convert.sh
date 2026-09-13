#!/usr/bin/env bash

set -uo pipefail

# Exports my syncthing api key to SYNCTHING_API_KEY.
# Put it in another script so I don't have to worry about my api key being public.
source ./EXPORT_SYNCTHING_API_KEY.sh

./convert.py --verbose | while IFS= read -r filepath; do
    echo "Converting: $filepath.note -> $filepath.svg"
    supernote-tool convert -a -t=svg --pdf-type=vector \
        -c "#fefefe,#c9c9c9,#9d9d9d,#000000" --exclude-background \
        "$filepath.note" "$filepath.svg"
    for file in "$filepath"*.svg ; do
        flatpak run org.inkscape.Inkscape \
            --actions="select-all;export-area-drawing;export-do" --export-overwrite \
            "$file"
    done
done
