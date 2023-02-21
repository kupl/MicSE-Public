# Usage : python3 benchmark.py <cores> <start_idx> <end_idx> <output_dir>
from datetime import datetime
import multiprocessing
import os
import subprocess
import time
import re
import sys


INSTR_QUERY_LIST = [["KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6", 2372, (218, 24), (1572, 24)],
                    ["KT1Ag29Dotu8iEigVrCARu7jmW5gkF1RyHUB", 1494, (333, 16), (550, 16), (551, 16)],
                    ["KT1ArrDG6dXqgvTH5RcyYFy4TmShG1MWajSr", 1812, (1377, 16), (1378, 16)],
                    ["KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV", 1477, (83, 28), (112, 24), (149, 24), (153, 24), (157, 24), (224, 24), (1035, 24)],
                    ["KT1CT7S2b9hXNRxRrEcany9sak1qe4aaFAZJ", 2158, (209, 24), (396, 24), (1415, 24)],
                    ["KT1DrJV8vhkdLEj76h1H9Q4irZDqAkMPo1Qf", 2256, (206, 24), (396, 24), (1490, 24)],
                    ["KT1Lrjm4rPcQNqQG5UVN2QvF1ouD9eDuFwbQ", 1476, (149, 24), (153, 24)],
                    ["KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9", 1556, (184, 40), (286, 89)],
                    ["KT1VemSYVVLsed4ejg1g3nfDkDUmW4rAN515", 2273, (567, 28)],
                    ["KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab", 2266, (206, 24), (395, 24), (1511, 24)],
                    ["KT18dDtdzvEj3Y9okKJxASMCyWfSscRfjtbP", 2069, (210, 24), (1380, 24)]]


OUTDIR_HEAD = '~/vagrant/benchmarks/result/'


def run(cmd):
    # print current datetime and execute command parameter
    print(f'{datetime.now().strftime("%H:%M:%S")} : {cmd}', flush=True)
    os.system(cmd)
    return 0

MAX_TIMEOUT = 900


# receive result file path
def parse_result(path: str):
    f = open(path, "rt")
    result = f.read()
    ## read file and return State, time information
    if "=== Final Result ===" in result:
        try:
            Time = re.findall(r"Time: (.*) sec", result)
            Time = int(float(Time[0]))
            found = re.findall(r"#Proved: (.*)\t\t#Refuted: (.*)\t\t#Failed: (.*)", result)
            found = list(map(int, list(found[0])))
            if found[0] == 1:
                status = "Proved"
            elif found[1] == 1:
                status = "Refuted"
            elif found[2] == 1:
                status = "Failed"
                Time = "T/O"
            else:
                print("Result goes to something wrong")
                exit(1)
            return status, Time
        except AttributeError:
            print("Please report to author while running script")
            pass
    else:
        return "Failed", "T/O"

BINARY_SUFFIX = [("baseline", "nonco"), ("micse", "syner")]

if __name__ == '__main__':
    # first make directory storing result file
    argc = len(sys.argv)
    if argc < 3 or argc > 5:
        print("Usage: python3 benchmark.py <cores> <start idx> <end_idx> <output_dir>")
        print("Usage: python3 benchmark.py <cores> <target idx> <output_dir>")
        exit(1)
    
    cores = int(sys.argv[1])

    # check cores
    if cores <= 0:
        print("The number of cores should be positive")
        exit(1)
    elif cores > multiprocessing.cpu_count():
        print("The number of cores is more than your machine's cpus")
        print("Recommand you use less than maximum cpu counts")
        exit(1)


    # check and determine idx range
    if argc == 5:
        start_idx, end_idx = int(sys.argv[2]), int(sys.argv[3])
        assert(start_idx <= end_idx)
    elif argc == 4:
        start_idx, end_idx = int(sys.argv[2]), int(sys.argv[2])
    else:
        start_idx, end_idx = 1, 30
    
    # determine and check output_dir and sub result directory
    output_dir = sys.argv[-1]

    is_dir_exists = os.path.exists(output_dir)
    if is_dir_exists == False:
        print("Output Directory is not present")
        exit(1)

    result_dir = output_dir + "/result_900"
    if os.path.exists(result_dir) == False:
        os.system(f"mkdir {result_dir}")
    for x in range(1, 31):
        if os.path.exists(f"{result_dir}/{x}") == False:
            os.system(f'mkdir {result_dir}/{x}')

    poolnum = cores
    idx_list = []
    with multiprocessing.Pool(processes=poolnum) as pool:
        # First Run MicSE, Second run Baseline
        for binary_suffix_tuple in BINARY_SUFFIX:
            binary, suffix = binary_suffix_tuple[0], binary_suffix_tuple[1]
            NUM = 1
            for contract_info in INSTR_QUERY_LIST:
                query_num = len(contract_info) - 2
                for idx in range(2, 2 + query_num):
                    while True:
                        psr = subprocess.run(
                            ['ps', '-e'], capture_output=True)
                        psr_output = psr.stdout.decode('utf-8').split()
                        if psr_output.count('timeout') < poolnum:
                            # If NUM is in range of start and end idx
                            # then execute command
                            if NUM >= start_idx and NUM <= end_idx: 
                                row, col = contract_info[idx][0], contract_info[idx][1]
                                contract_addr = contract_info[0]
                                command = f"timeout 1000 {binary} -T 900 -d -q {row} {col} -I ~/vagrant/benchmarks/evaluation/{contract_addr}.tz -S ~/vagrant/benchmarks/evaluation/{contract_addr}.storage.tz > {result_dir}/{NUM}/{contract_addr}.{suffix} 2>&1 &"
                                pool.map(run, [command])
                                if not NUM in idx_list:
                                    idx_list.append(NUM)
                            NUM += 1
                            time.sleep(1)
                            break
                        else:
                            time.sleep(10)
    

    # check all processes are done
    while True:
        psr = subprocess.run(
            ['ps', '-e'], capture_output=True)
        psr_output = psr.stdout.decode('utf-8').split()
        if psr_output.count('timeout') > 0:
            time.sleep(10)
        else:
            break
    
    print("[*] End of Benchmarking")
    print("[*] Now Start to parse result and show table in paper")

    import pandas as pd

    column_names = pd.DataFrame([["Contact Addr.", ""],
                                ["Inst", ""],
                                ["QLoc", ""],
                                ["Baseline", "Result"],
                                ["Baseline", "Time(s)"],
                                ["MicSE", "Result"],
                                ["MicSE", "Time(s)"],
                                ["Speedup", ""]],
                                columns=["No.", ""])
    rows  = []
    idx = 1

    for contract_info in INSTR_QUERY_LIST:
        query_num = len(contract_info) - 2
        for i in range(query_num):
            if idx in idx_list:
                contract_addr, inst = contract_info[0], contract_info[1]
                qloc = contract_info[2 + i][0]
                filename = f"{contract_addr}.nonco"
                filepath = f"{result_dir}/{idx}/{filename}"
                baseline_status, baseline_time_second = parse_result(filepath)
                filename = f"{contract_addr}.syner"
                filepath = f"{result_dir}/{idx}/{filename}"
                micse_status, micse_time_second = parse_result(filepath)
                if type(baseline_time_second) == int:
                    speedup = "> " + str(round(baseline_time_second / micse_time_second, 1))
                else:
                    speedup = "> " + str(round(900 / micse_time_second, 1))
                row = [contract_addr, inst, qloc, baseline_status, baseline_time_second, micse_status, micse_time_second, speedup]
                rows.append(row)
            idx += 1
    
    columns = pd.MultiIndex.from_frame(column_names)
    index = ["#" + str(i).rjust(2, "0") for i in idx_list]

    df = pd.DataFrame(rows, columns=columns, index=index)
    print(df)