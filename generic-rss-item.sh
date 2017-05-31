#!/bin/sh

  # https://www.youtube.com/watch\?v\=ikAb-NYkseI
  x="$(http "$1")"

  echo "    <item>"
  echo "$x" | gawk 'match($0, /<title>(.*?)<\/title>/, ary) {print "      <title>"ary[1]"</title>"}'
  echo "$x" | gawk 'match($0, /<meta name="description" content="(.*)">/, ary) {print "      <description>"ary[1]"</description>"}'
  echo "      <link>$1</link>"
  echo "      <guid isPermaLink=\"false\">$1</guid>"
  echo "      <pubDate>$(date -u "+%a, %d %b %Y %H:%M:%S GMT")</pubDate>"
  echo "    </item>"

