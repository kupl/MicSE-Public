#!/bin/bash
LIST_FILE_NAME="
KT19TiuQRTNo4nsybpQQzunonJo1wAFdvRA5
KT1Lrjm4rPcQNqQG5UVN2QvF1ouD9eDuFwbQ
KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV
KT1Ep5RX2VVyP7zD3kYhEzJyJgfb8oBSUv2H
KT1Ag29Dotu8iEigVrCARu7jmW5gkF1RyHUB
KT1AKNCvvGN8QEiL6bd8UHDXq4tmiNRsKYs9
KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9
KT1R8wDzRrsTmqq6UykpSezTgwXU6VGnwHwc
KT1BZyfCcgMRb7gniyyM6iobEYVQc9vECGua
KT1ArrDG6dXqgvTH5RcyYFy4TmShG1MWajSr
KT1Hkg5qeNhfwpKW4fXvq7HGZB9z2EnmCCA9
KT18dDtdzvEj3Y9okKJxASMCyWfSscRfjtbP
KT1KeKqrvtMujUGdrkwxhtuyVSqNBHPZnoyt
KT1WtkKhbN6yLBTcPt2TrCfkRthMW5uTHm2F
KT1CT7S2b9hXNRxRrEcany9sak1qe4aaFAZJ
KT1QaQSUUbBvoxb4sShbQxeUPv1ZyD5sX6ff
KT1DrJV8vhkdLEj76h1H9Q4irZDqAkMPo1Qf
KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab
KT1FEdxBE91HAuPvD3T41tnHgsrSZMBW3vsF
KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6
KT1NmoofGosSaWFKgAbt7AMTqnV1xfqeAhLT
KT1NM7a8r2u96y9pyH1aHfSa6TpQ23ZwdYsX
KT1LXVbM8Lhf5HV3C5ebhQWp4H1rezMCfMKz
"
echo ""
echo "<<<< File Name List >>>>"
IDX=1
for FILE_NAME in $LIST_FILE_NAME; do
    echo "file name ${IDX} : ${FILE_NAME}.tz"
    CODEFILE="benchmarks/top30/${FILE_NAME}.tz"
    STORAGEFILE="benchmarks/top30/${FILE_NAME}.storage.tz"
    timeout 4800 micse -T 3600 -I $CODEFILE -S $STORAGEFILE -d > ~/MicSE/result/nonco/${FILE_NAME}.nonco 2>&1 &
    timeout 4800 micse-s -T 3600 -I $CODEFILE -S $STORAGEFILE -d > ~/MicSE/result/syner/${FILE_NAME}.syner 2>&1 &
    FLAG=`expr $IDX % 4`
    if [[ $FLAG -eq 0 ]]
    then
	sleep 1h
    fi
    IDX=`expr $IDX + 1`
done
