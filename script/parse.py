import re
import sys
from tabulate import tabulate

LIST_FILE_NAME=[
    "KT19TiuQRTNo4nsybpQQzunonJo1wAFdvRA5",
    "KT1Lrjm4rPcQNqQG5UVN2QvF1ouD9eDuFwbQ",
    "KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV",
    "KT1Ep5RX2VVyP7zD3kYhEzJyJgfb8oBSUv2H",
    "KT1Ag29Dotu8iEigVrCARu7jmW5gkF1RyHUB",
    "KT1AKNCvvGN8QEiL6bd8UHDXq4tmiNRsKYs9",
    "KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9",
    "KT1R8wDzRrsTmqq6UykpSezTgwXU6VGnwHwc",
    "KT1BZyfCcgMRb7gniyyM6iobEYVQc9vECGua",
    "KT1ArrDG6dXqgvTH5RcyYFy4TmShG1MWajSr",
    "KT1Hkg5qeNhfwpKW4fXvq7HGZB9z2EnmCCA9",
    "KT18dDtdzvEj3Y9okKJxASMCyWfSscRfjtbP",
    "KT1KeKqrvtMujUGdrkwxhtuyVSqNBHPZnoyt",
    "KT1WtkKhbN6yLBTcPt2TrCfkRthMW5uTHm2F",
    "KT1CT7S2b9hXNRxRrEcany9sak1qe4aaFAZJ",
    "KT1QaQSUUbBvoxb4sShbQxeUPv1ZyD5sX6ff",
    "KT1DrJV8vhkdLEj76h1H9Q4irZDqAkMPo1Qf",
    "KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab",
    "KT1FEdxBE91HAuPvD3T41tnHgsrSZMBW3vsF",
    "KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6",
    "KT1NmoofGosSaWFKgAbt7AMTqnV1xfqeAhLT",
    "KT1NM7a8r2u96y9pyH1aHfSa6TpQ23ZwdYsX",
    "KT1LXVbM8Lhf5HV3C5ebhQWp4H1rezMCfMKz",
    "KT1GALBSRLbY3iNb1P1Dzbdrx1Phu9d9f4Xv"
]

LIST_QUERY_NUM=[
    3, 9, 9, 12, 8, 12, 9, 3, 17, 2, 11, 8, 7, 3, 10, 6, 10, 10, 3, 10, 13, 4, 3
]

def parse_nonco_result(idx: int):
    f = open(f"/home/vagrant/MicSE/benchmarks/result/{idx}/{LIST_FILE_NAME[idx-1]}.nonco", "rt")
    result = f.read()
    if "=== Final Result ===" in result:
        try:
            found = re.findall(r"#Proved: (.*)\t\t#Refuted: (.*)\t\t#Failed: (.*)", result)
            found = list(map(int, list(found[0])))
            assert(sum(found) == LIST_QUERY_NUM[idx-1])
            time = re.findall(r"Time: (.*) sec", result)
            return found + [int(float(time[0]))]
        except AttributeError:
            print("Please DM to hyun Do if you see this message while running script")
            pass
    elif "P/R/U/F" in result:
        try:
            found = re.findall(r"P/R/U/F = (.*) / (.*) / (.*) / (.*) , expanding-ppath = ", result)
            found = list(map(int, list(found[-1])))
            found = [found[0], found[1], found[2]+found[3]]
            assert(sum(found) == LIST_QUERY_NUM[idx-1])
            return found + [4800]
        except AttributeError:
            print("Please DM to hyun Do if you see this message while running script")
            pass
    else:
        found = [0, 0, LIST_QUERY_NUM[idx-1]]
        return found + [4800]


def make_benchmark_table(start: int, end: int):
    Query_info = []
    for i in range(start, end + 1):
        Query_info.append([i, LIST_FILE_NAME[i-1], LIST_QUERY_NUM[i-1]] + parse_nonco_result(i))
    
    table = tabulate(Query_info, headers=["", "Address", "#Query", "#Proved", "#Refuted", "#Failed", "Time (s)"], tablefmt="fancy_grid")
    print(table)


assert(len(sys.argv) == 3)

start = int(sys.argv[1])
end   = int(sys.argv[2])

make_benchmark_table(start, end)