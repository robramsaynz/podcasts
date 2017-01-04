#!/bin/sh
#
# $ ./list-to-items.sh list.txt | pbcopy
#
# Then past into rss file.
# 

file="$1"

gawk '{
    url = $0;
    guid = $0;

    match($0, /([^\/]*)(......)\.mp3/, rslt);
    performer = rslt[1];
    date = rslt[2];

    "date -u -jf %d%m%y%H%M " date "0000 +\"%a, %d %b %Y %H:%M:%S GMT\"" | getline longdate
    "date -u -jf %d%m%y " date " +%Y-%m-%d" | getline shortdate

    print "";
    print "    <item>";
    print "      <title>"shortdate"  "performer"</title>";
    print "      <enclosure url=\""url"\" type=\"audio/mpeg\" length=\"1\"/>";
    print "      <guid isPermaLink=\"false\">"guid"</guid>";
    print "      <pubDate>"longdate"</pubDate>";
    print "    </item>";
}' "$file"

