#!/bin/sh
#
# ./list-to-names.sh list.txt
#

file="$1"

gawk '{
    match($0, /([^\/]*)(......)\.mp3/, rslt);
    performer = rslt[1];
    date = rslt[2];

    "date -u -jf %d%m%y " date " +%Y-%m-%d" | getline shortdate

    print shortdate"  "performer;
}' "$file"

