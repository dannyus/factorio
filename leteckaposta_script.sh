#!/bin/bash

if [ $# -eq 0 ];then
  cat <<EndHelp
Usage: $0 URL ...
EndHelp
else
  tmpdir="$( mktemp -d )"
  while [ $# -gt 0 ];do
    url1="$1"
    shift
    output1="$( wget -O - -q --keep-session-cookies --save-cookies="$tmpdir/cookies" "$url1" )"
    baseurl="$( echo "$url1" | perl -ne 'print "$1" if m,^(https?://[^/]+)/,i;' )"
    urlpath="$( echo "$output1" | perl -e '
      undef $/; $a=<STDIN>;
      print $p if ((($t)=($a=~m,(<a[^>]*class=["\x27]download-link["\x27][^>]*>),is)) and (($p)=($t=~m,href=["\x27](/file/[^"\x27]+)["\x27],is)));
      '
    )"
    file="$( echo "$output1" | perl -e '
      undef $/; $a=<STDIN>;
      print $f if (($f)=($a=~m,<a[^>]*class=["\x27]download-link["\x27][^>]*>([^<]+)</a>,is));
      '
    )"
    echo "BASEURL: $baseurl"
    echo "URLPATH: $urlpath"
    echo "FILE: $file"
    if [ -n "$file" ] && [ -n "$urlpath" ];then
      wget -c -O "$file" --load-cookies="$tmpdir/cookies" --referer="$url1" "${baseurl}${urlpath}"
    else
      echo "FAILED"
      exit 1
    fi
  done
  rm -rf "$tmpdir"
fi