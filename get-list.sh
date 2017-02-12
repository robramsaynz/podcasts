#!/bin/sh
#
# ./get-list.sh >> list.txt
#

curl http://rinse.fm/podcasts/ | sed -E -n -e '/download="http:\/\/podcast[^ ]*/p' | sed -E -e 's/.*download="//g' -e 's/" .*//' > list.txt
curl http://rinse.fm/podcasts/?page=2 | sed -E -n -e '/download="http:\/\/podcast[^ ]*/p' | sed -E -e 's/.*download="//g' -e 's/" .*//' >> list.txt
curl http://rinse.fm/podcasts/?page=3 | sed -E -n -e '/download="http:\/\/podcast[^ ]*/p' | sed -E -e 's/.*download="//g' -e 's/" .*//' >> list.txt

