#!/bin/sh

  # https://www.youtube.com/watch\?v\=ikAb-NYkseI
  x="$(http "$1")"

  echo "    <item>"
  echo "$x" | gawk 'match($0, /<title>(.*?)<\/title>/, ary) {print "      <title>"ary[1]"</title>"}'
  echo "$x" | gawk 'match($0, /<meta name="description" content="(.*)">/, ary) {print "      <description>"ary[1]"</description>"}'
  echo "      <link>$1</link>"
  echo "      <guid isPermaLink=\"false\">$1</guid>"

  date="$(echo "$x" | grep '<meta' | gawk 'match($0, /<meta itemprop="datePublished" content="(.*?)">/, ary) {print ary[1]}' )"
  date_822="$(date -u -jf "%Y-%m-%d" "$date" "+%a, %d %b %Y %H:%M:%S GMT")"
  echo "      <pubDate>$date_822</pubDate>"

  echo "    </item>"

