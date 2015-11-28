#!/bin/sh
# colorize netstat output

PATH=/usr/local/bin:$PATH # Needed for GeekTool.app

# My actual script uses literal <Esc> instead of \033, but that wouldn't copy 'n paste
# properly here.  The literal <Esc>'s are not the cause of the bug; they are a new addition,
# and anyway I switched back to \033 for testing purposes.

red="[31m"
gre="[32m"
yel="[33m"
blu="[34m"
pur="[35m"
cya="[36m"
nun="[0m"

netstat -W -f inet \
| gsed \
  -e "/localhost*.*localhost/d" \
  -e '/\(^Proto\|ESTABLISH\|WAIT\|LISTEN\|CLOSING\|SYN\|ACK\)/!d' \
  -e "s/^.* ESTABLISH.*$/$gre&$nun/" \
  -e "s/^.* LIST.*$/$cya&$nun/"      \
  -e "s/^.* *.WAIT.*$/$red&$nun/"    \
  -e "s/^.* CLOSING$/$red&$nun/"     \
  -e "s/^.* SYN.*$/$yel&$nun/"       \
  -e "s/^.* FIN.*$/$yel&$nun/"       \
  -e "s/^.* *.ACK/$yel&$nun/"        \
  -e "/^Proto\//d"                   \
  -e "/^Proto Recv-Q Send-Q *\(unit\|vendor\)/d"

# Call netstat to check the open ports.
# Filter out trivial lines that aren't helpful.
# Insert the color.
# The last two lines filter out crap that started appearing on
#   Yosemite.
