#!/bin/bash
set -- $(getopt :S:E:j: "$@")
#default option
START=1
END=23
CORES=1
while [ -n "$1" ]
do
        case "$1" in
                -S) echo "Found the -S option";START=$2;
                        echo "Found the -S option, with from $START"
                        shift;;
                -E) echo "Found the -E option";END=$2;
                        echo "Found the -E option, with from $END"
                        shift;;
                -j) echo "Found the -j option";CORES=$2;
                        echo "Found the -j option, now cores used are $CORES"
                        shift;;
                --) shift
                        break;;
                *) echo "$1 is not an option";;
        esac
        shift
done

if [ $START -gt $END ];then
        echo "START number is larger than End number"
        exit 1
fi

LIST_FILE_NAME=(
"KT19TiuQRTNo4nsybpQQzunonJo1wAFdvRA5"
"KT1Lrjm4rPcQNqQG5UVN2QvF1ouD9eDuFwbQ"
"KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV"
"KT1Ep5RX2VVyP7zD3kYhEzJyJgfb8oBSUv2H"
"KT1Ag29Dotu8iEigVrCARu7jmW5gkF1RyHUB"
"KT1AKNCvvGN8QEiL6bd8UHDXq4tmiNRsKYs9"
"KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9"
"KT1R8wDzRrsTmqq6UykpSezTgwXU6VGnwHwc"
"KT1BZyfCcgMRb7gniyyM6iobEYVQc9vECGua"
"KT1ArrDG6dXqgvTH5RcyYFy4TmShG1MWajSr"
"KT1Hkg5qeNhfwpKW4fXvq7HGZB9z2EnmCCA9"
"KT18dDtdzvEj3Y9okKJxASMCyWfSscRfjtbP"
"KT1KeKqrvtMujUGdrkwxhtuyVSqNBHPZnoyt"
"KT1WtkKhbN6yLBTcPt2TrCfkRthMW5uTHm2F"
"KT1CT7S2b9hXNRxRrEcany9sak1qe4aaFAZJ"
"KT1QaQSUUbBvoxb4sShbQxeUPv1ZyD5sX6ff"
"KT1DrJV8vhkdLEj76h1H9Q4irZDqAkMPo1Qf"
"KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab"
"KT1FEdxBE91HAuPvD3T41tnHgsrSZMBW3vsF"
"KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6"
"KT1NmoofGosSaWFKgAbt7AMTqnV1xfqeAhLT"
"KT1NM7a8r2u96y9pyH1aHfSa6TpQ23ZwdYsX"
"KT1LXVbM8Lhf5HV3C5ebhQWp4H1rezMCfMKz"
)

echo ""
echo "<<<< File Name List >>>>"
IDX=`expr $START`
USED=0
until [ $IDX -eq $END ]
do
    echo "${IDX}'th file name : ${LIST_FILE_NAME[IDX - 1]}.tz"
    CODEFILE="${LIST_FILE_NAME[IDX - 1]}.tz"
    STORAGEFILE="${LIST_FILE_NAME[IDX - 1]}.storage.tz"
    echo $CODEFILE $STORAGEFILE
    if [ ! -d ~/MicSE/benchmarks/result/${IDX} ]; then
        mkdir ~/MicSE/benchmarks/result/${IDX}
    fi
    if [ $CORES -eq 1 ]; then
        timeout 4800 micse -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/benchmarks/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.nonco 2>&1 &
        sleep 4800
        timeout 4800 micse-s -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/benchmarks/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.syner 2>&1 &
        sleep 4800
    elif [ $CORES -gt 1 ]; then
        timeout 4800 micse -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.nonco 2>&1 &
        USED=`expr $USED + 1`
        if [ $USED -eq $CORES ]; then
            sleep 4800
            USED=0
        fi
        timeout 4800 micse-s -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.syner 2>&1 &
        USED=`expr $USED + 1`
        if [ $USED -eq $CORES ]; then
            sleep 4800
            USED=0
        fi
    else
        echo "Core number should be non-negative"
        exit 1
    fi
    IDX=`expr $IDX + 1`
done

##### Parsing result of benchmarks and displays it in chart
