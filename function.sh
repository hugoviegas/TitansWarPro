#!/bin/bash
link()
{
  echo "$1"
  (
    w3m -cookie -o http_proxy="$PROXY" -o accept_encoding=UTF-8 -debug -dump "$URL/$1" -o user_agent="$(shuf -n1 "$TMP"/userAgent.txt)" | tail -n0
  ) </dev/null &>/dev/null &
    time_exit 17
}