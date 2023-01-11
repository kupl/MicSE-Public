#!/bin/bash
#set -- $(getopt :S:E:j:h "$@")
#default option
Help()
{
    echo "Syntax: ./testMich.sh [-S|E|j|h]"
    echo "options:"
    echo "S     indicate Start index in benchmarks table (default: 1)"
    echo "E     indicate End   index in benchmarks table (default: 23)"
    echo "j     indicate the number of cores (default: 1)"
    echo "h     displays the option"
    echo ""
}
START=1
END=24
CORES=1
while getopts ":S:E:j:h" option; 
do
    case "$option" in
        S) echo "Found the -S option";START=$OPTARG;
                echo "Found the -S option, with from $START";;
        E) echo "Found the -E option";END=$OPTARG;
                echo "Found the -E option, with from $END";;
        j) echo "Found the -j option";CORES=$OPTARG;
                echo "Found the -j option, now cores used are $CORES";;
        h) echo "Found help option";
                Help
                exit;;
        #--) shift
        #        break;;
        \?) echo "$1 is not an option";
                Help
                exit;;
    esac
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
"KT1GALBSRLbY3iNb1P1Dzbdrx1Phu9d9f4Xv"
)

echo ""
echo "<<<< File Name List >>>>"
IDX=`expr $START`
USED=0
until [ $IDX -gt $END ]
do
    echo "${IDX}'th file name : ${LIST_FILE_NAME[IDX - 1]}.tz"
    CODEFILE="${LIST_FILE_NAME[IDX - 1]}.tz"
    STORAGEFILE="${LIST_FILE_NAME[IDX - 1]}.storage.tz"
    echo $CODEFILE $STORAGEFILE
    if [ ! -d ~/MicSE/benchmarks/result/${IDX} ]; then
        mkdir ~/MicSE/benchmarks/result/${IDX}
    fi
    if [ $CORES -eq 1 ]; then
        timeout 4800 micse.naive_trxpath_main -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/benchmarks/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.nonco 2>&1 &
        echo "Start New micse"
        sleep 30
        while [ 1 ]
        do
            if [ $(pgrep -xc micse.naive_trx) -eq 0 ] ## micse is done
            then
                echo "Terminated micse"
                break
            else
                sleep 480
            fi
        done
        timeout 4800 micse-s -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/benchmarks/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.syner 2>&1 &
        echo "Start New micse-s"
        sleep 30
        while [ 1 ]
        do
            if [ $(pgrep -xc micse-s) -eq 0 ] ## micse-s is done
            then
                echo "Terminated micse-s"
                break
            else
                sleep 480
            fi
        done
    elif [ $CORES -gt 1 ]; then
        timeout 4800 micse.naive_trxpath_main -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.nonco 2>&1 &
        USED=$(pgrep -c micse)
        if [ $USED -eq $CORES ]; then
            while [ 1 ]
            do
                if [ $(pgrep -c micse) -lt 3 ] ## all micse and micse-s process are done
                then
                    USED=$(pgrep -c micse)
                    break
                fi
                sleep 480
            done
        fi
        timeout 4800 micse-s -T 4800 -I ~/MicSE/benchmarks/top30/$CODEFILE -S ~/MicSE/benchmarks/top30/$STORAGEFILE -d > ~/MicSE/result/${IDX}/${LIST_FILE_NAME[IDX - 1]}.syner 2>&1 &
        USED=$(pgrep -c micse)
        if [ $USED -eq $CORES ]; then
            while [ 1 ]
            do
                if [ $(pgrep -c micse) -lt 3 ] ## all micse and micse-s process are done
                then
                    USED=$(pgrep -c micse)
                    break
                fi
                sleep 480
            done
        fi
    else
        echo "Core number should be non-negative"
        exit 1
    fi
    IDX=`expr $IDX + 1`
done

echo "Benchmarking is over!!"

##### Parsing result of benchmarks and displays it in chart
python3 ~/MicSE/parse.py $START $END