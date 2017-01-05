#!/bin/sh
#
# $ ./only-favourites.sh list.txt | ./list-to-items.sh - | pbcopy
#
# Then past into rss file.
# 

file="$1"

awk '
    $0 ~ "Huntleys.*Palmers|UncleDugs|Keysound|Stamina|Hospital|Hessle|Metalhead|LobsterTheremin|Swamp81" {
        print
}' "$file"

