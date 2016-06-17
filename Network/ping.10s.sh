#!/bin/bash

# This is a plugin of Bitbar
# https://github.com/matryer/bitbar
# It shows current ping to some servers at the top Menubar
# This helps me to know my current connection speed
#
# Authors: (Trung Đinh Quang) trungdq88@gmail.com and (Grant Sherrick) https://github.com/thealmightygrant

MAX_PING=10000
SITES=(www.wordspeak.org gemini.wordspeak.org bigpond.com google.com tpg.com.au 10.20.20.41)

HAS_UNREACHABLE_SITE=0
UNREACHABLE_PING_TIME=-1

#grab ping times for all sites
REACHABLE_SITE_COUNT=0
SITE_INDEX=0
PING_TIMES=

while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
    NEXT_SITE="${SITES[$SITE_INDEX]}"
    NEXT_PING_TIME=$(ping -c 2 -n -q "$NEXT_SITE" 2>/dev/null | awk -F '/' 'END {printf "%d\n", $5}')
    if [ "$NEXT_PING_TIME" -eq 0 ]; then
        NEXT_PING_TIME=$UNREACHABLE_PING_TIME
        HAS_UNREACHABLE_SITE=1
    else
        REACHABLE_SITE_COUNT=$(( $REACHABLE_SITE_COUNT + 1 ))
    fi
    if [ -z "$PING_TIMES" ]; then
        PING_TIMES=($NEXT_PING_TIME)
    else
        PING_TIMES=(${PING_TIMES[@]} $NEXT_PING_TIME)
    fi
    SITE_INDEX=$(( $SITE_INDEX + 1 ))
done

# Calculate the average ping for reachable sites
if [ $REACHABLE_SITE_COUNT -gt 0 ]; then
    SITE_INDEX=0
    AVG=0
    while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
        if [ ${PING_TIMES[$SITE_INDEX]} -gt $UNREACHABLE_PING_TIME ]; then
            AVG=$(( ($AVG + ${PING_TIMES[$SITE_INDEX]}) ))
        fi
        SITE_INDEX=$(( $SITE_INDEX + 1 ))
    done
    AVG=$(( $AVG / $REACHABLE_SITE_COUNT ))
    
    # Calculate STD dev
    SITE_INDEX=0
    AVG_DEVS=0
    while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
        if [ ${PING_TIMES[$SITE_INDEX]} -gt $UNREACHABLE_PING_TIME ]; then
            AVG_DEVS=$(( $AVG_DEVS + (${PING_TIMES[$SITE_INDEX]} - $AVG)**2 ))
        fi
        SITE_INDEX=$(( $SITE_INDEX + 1 ))
    done
    AVG_DEVS=$(( $AVG_DEVS / $REACHABLE_SITE_COUNT ))
    SD=$(echo "sqrt ( $AVG_DEVS )" | bc -l | awk '{printf "%d\n", $1}')
else
    # Make it so that we get a skull and crossbones
    AVG=$MAX_PING
fi

# Define color
COLOR="#cc3b3b"
MSG="$AVG"'±'"$SD"'⚡'

if [ $AVG -ge $MAX_PING ]; then
    COLOR="#acacac"
    MSG=" ☠ "
elif [ $AVG -ge 1000 ] && [ $AVG -lt $MAX_PING ]; then
    COLOR="#ff0101"
elif [ $AVG -ge 600 ] && [ $AVG -lt 1000 ]; then
    COLOR="#cc673b"
elif [ $AVG -ge 300 ] && [ $AVG -lt 600 ]; then
    COLOR="#ce8458"
elif [ $AVG -ge 100 ] && [ $AVG -lt 300 ]; then
    COLOR="#6bbb15"
elif [ $AVG -ge 50 ] && [ $AVG -lt 100 ]; then
    COLOR="#0ed812"
else
    COLOR="#e506ff"
fi

if [ $HAS_UNREACHABLE_SITE -eq 1 ]; then
    FONT="Impact"
else
    FONT="Georgia"
fi

echo "$MSG | font="$FONT" color=$COLOR size=10"
echo "---"
SITE_INDEX=0
while [ $SITE_INDEX -lt ${#SITES[@]} ]; do
    PING_TIME=${PING_TIMES[$SITE_INDEX]}
    if [ $PING_TIME -eq $UNREACHABLE_PING_TIME ]; then
        PING_TIME="☠"
    else
        PING_TIME="$PING_TIME ms"
    fi

    echo "${SITES[$SITE_INDEX]}: $PING_TIME"
    SITE_INDEX=$(( $SITE_INDEX + 1 ))
done
