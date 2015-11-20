#! /bin/sh

##################
# CPU Meter Code #
##################

free=`top -l 2 | grep "CPU usage" | tail -1 | awk '{printf "%.0f", $7+0}'`

let used=100-$free

let count=5
colour='\033[0;32m'
echo "CPU \c"

while [ $count -le 100 ]
do
    if [ $count -le $used ]
    then
        if [ $count -le 50 ]
            then
                echo "\033[1;32m|\c" # green
                colour='\033[0;32m'

        elif [ $count -le 75 ]
            then
                echo "\033[1;33m|\c" # yellow
                colour='\033[0;33m'

        elif [ $count -le 100 ]
            then
                echo "\033[1;31m|\c" # red
                colour='\033[0;31m'
            fi
    else
        echo " \c"
    fi
    let count=${count}+5
done

# Default Output. Place a # (comment) sign at the start of the next "echo" line below if you wish to used the Extended output.

# echo "$colour $used%\c"

# Extended output. Remove the # (comment) sign from the next "echo" line below to use.

echo "$colour $used% Utilisation\c"

unset colour
echo "\033[0;39m"

##################
# RAM Meter Code #
##################

used_ram=`top -l 1 | awk '/PhysMem/ {print $2}' | sed "s/M//"`

free_ram=`top -l 1 | awk '/PhysMem/ {print $6}' | sed "s/M//"`

let total_ram=$used_ram+$free_ram

used_percent=$(echo "scale=2; $used_ram / $total_ram * 100" | bc)
used_percent=`echo $used_percent | cut -d . -f 1`

# convert free_ram to GB not MB for the Extended output feature
free_ram=$(echo "scale=2; $free_ram / 1024" | bc)

let count=5
colour='\033[0;32m'
echo "RAM \c"

while [ $count -le 100 ]
do
    if [ $count -le $used_percent ]
    then
        if [ $count -le 50 ]
        then
            echo "\033[1;32m|\c" # green
            colour='\033[0;32m'
        elif [ $count -le 75 ]
        then
            echo "\033[1;33m|\c" # yellow
            colour='\033[0;33m'
        elif [ $count -le 100 ]
        then
            echo "\033[1;31m|\c" # red
            colour='\033[0;31m'
        fi
    else
        echo " \c"
    fi
    let count=${count}+5
done

# Default output. Place a # (comment) sign at the start of the next "echo" line if wishing top use the Extended output.

# echo "$colour $used_percent%\c"

# Extended output. Remove the # sign from the "echo" line below to use.

echo "$colour $used_percent% Used, ${free_ram}GB Free\c"

unset colour
echo "\033[0;39m"

######################
# BATTERY Meter Code #
######################

max_charge=`system_profiler -detailLevel basic SPPowerDataType | grep mAh | grep Capacity | awk '{print $5 }'`
actual_charge=`system_profiler -detailLevel basic SPPowerDataType | grep mAh | grep Remaining | awk '{print $4 }'`

avail=$(echo "scale=2; $actual_charge / $max_charge * 100" | bc)
avail=`echo $avail | cut -d . -f 1`

let count=5

# set colour to red in case batt is less than 5% as it won't do the while (colour coding) loop if $avail is less than the counter.

colour='\033[0;31m'
bar=''

echo "Bat \c"

while [ $count -le 100 ]
do
    if [ $count -le $avail ]
    then
        if [ $count -le 25 ]
        then
            bar="\033[1;31m|$bar" # red
            colour='\033[0;31m'
        elif [ $count -le 50 ]
        then
            bar="\033[1;33m|$bar" # yellow
            colour='\033[0;33m'
        elif [ $count -gt 50 ]
        then
            bar="\033[1;32m|$bar" # green
            colour='\033[0;32m'
        fi
    else
        bar=" $bar"
    fi
    let count=${count}+5
done

# Default output. Place a # (comment) sign at the start of the next "echo" line below if you wish to use the Extended output.

#echo "$bar$colour $avail%\c"

# Extended output. Remove the # (comment) sign from the next "echo" line below to use.

echo "$bar$colour $avail% charged, $actual_charge(mAh) Remain\c"

unset bar
unset colour
echo "\033[0;39m"

echo ""
