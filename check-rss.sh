#!/bin/sh
#
# Usage:  ./check-rss.sh

check() {
  echo "--- $1 ---"
  echo

  http http://www.feedvalidator.org/check.cgi\?url\=https%3A%2F%2Frobramsaynz.github.io%2Fpodcasts%2F$1 \
  | gawk '/This is a valid RSS feed/ {print} /This feed does not validate/ {print} /interoperability with the widest range/ {print} /implementing the following recommendations/ {print}' \
  | html2text
  echo
  echo "http://www.feedvalidator.org/check.cgi?url=https%3A%2F%2Frobramsaynz.github.io%2Fpodcasts%2F$1"
  echo
}

check manual.rss
check rinse-fm.rss

