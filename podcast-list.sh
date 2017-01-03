#!/bin/sh

#curl http://rinse.fm/podcasts/ | sed -E -n -e '/download="http:\/\/podcast[^ ]*/p' | sed -E -e 's/.*download="//g' -e 's/" .*//' > list.txt
#curl http://rinse.fm/podcasts/?page=2 | sed -E -n -e '/download="http:\/\/podcast[^ ]*/p' | sed -E -e 's/.*download="//g' -e 's/" .*//' >> list.txt
#curl http://rinse.fm/podcasts/?page=3 | sed -E -n -e '/download="http:\/\/podcast[^ ]*/p' | sed -E -e 's/.*download="//g' -e 's/" .*//' >> list.txt

gawk '{
    match($0, /([^\/]*)(......)\.mp3/, rslt);
    performer = rslt[1];
    date = rslt[2];

    "date -u -jf %d%m%y " date " +%Y-%m-%d" | getline shortdate

    print shortdate"  "performer;
}' list.txt

gawk '$1 ~ /Uncle/ {
    url = $0;
    guid = $0;

    match($0, /([^\/]*)(......)\.mp3/, rslt);
    performer = rslt[1];
    date = rslt[2];

    "date -u -jf %d%m%y%H%M " date "0000" | getline longdate
    "date -u -jf %d%m%y " date " +%Y-%m-%d" | getline shortdate

    print "    <item>";
    print "      <title>"shortdate"  "performer"</title>";
    print "      <enclosure url=\""url"\" type=\"audio/mpeg\" length=\"1\"/>";
    print "      <guid isPermaLink=\"false\">"guid"</guid>";
    print "      <pubDate>"longdate"</pubDate>";
    print "    </item>";
}' list.txt

