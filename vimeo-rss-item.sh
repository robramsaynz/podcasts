#!/bin/sh

  # https://www.youtube.com/watch\?v\=ikAb-NYkseI
  x="$(http "$1")"

  echo "    <item>"
  echo "$x" | gawk 'match($0, /<title>(.*?)<\/title>/, ary) {print "      <title>"ary[1]"</title>"}'
  echo "$x" | gawk 'match($0, /<meta name="description" content="(.*)">/, ary) {print "      <description>"ary[1]"</description>"}'
  echo "      <link>$1</link>"
  echo "      <guid isPermaLink=\"false\">$1</guid>"

  date="$(echo "$x" | gawk 'match($0, /<time datetime="(.*?):(..)"/, ary) {print ary[1]ary[2]}' )"
echo $date
  date_822="$(date -u -jf "%Y-%m-%dT%H:%M:%S%z" "$date" "+%a, %d %b %Y %H:%M:%S GMT")"
  echo "      <pubDate>$date_822</pubDate>"

  echo "    </item>"

