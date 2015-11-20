#! /bin/sh

#####################
# WIFI Network Code #
#####################

# Script to get the current ip addresses in use
# N.B. this was written for my Macbook Pro and iMac.
# Check the en0, en1, etc assignments for a Mac Pro
# which has 2 ethernet ports, not 1, also
# Macbook Air has no ethernet port

#SMC 1.5 and EFI 2.3 Updates  (Nov. 2011) have killed this method for obtaining SSID info
#wifi_network=`system_profiler -detailLevel basic SPAirPortDataType | head -25 | tail -1 | awk '{print $1}' | sed "s/://"`

wifi_network=`/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I | awk -F: '/ SSID: / {print $2}' | sed -e 's/SSID: //' | sed -e 's/ //'`

wifi=`ifconfig en0 | grep "broadcast" | awk '{print $2}'`
ethe=`ifconfig en3 | grep "broadcast" | awk '{print $2}'`

if [ "$wifi" != "" ]
then
        echo "🔵 Wireless ip: $wifi on $wifi_network"
else
        echo "🔴 Wireless ip: NO CONNECTION"
fi

if [ "$ethe" != "" ]
then
        echo "🔵 Ethernet ip: $ethe"
else
        echo "🔴 Ethernet ip: NO CONNECTION"
fi

external=`curl --silent http://checkip.dyndns.org | awk '{print $6}' | cut -f 1 -d '<'`

if [ "$external" != "" ]
then
        echo "🌎 External ip: $external"
else
        echo "🔴 NO INTERNET CONNECTION"
fi
