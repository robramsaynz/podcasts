#!/bin/sh
#
# $ ./limit-favourites.sh list.txt | ./list-to-items.sh list.txt | pbcopy
#
# Then past into rss file.
# 

file="$1"

awk '
    $0 ~ "Huntleys.*Palmers|UncleDugs|Keysound|Stamina|Hospital|Hessle|Metalhead|LobsterTheremin|Swamp81" {
        print
}' "$file"

