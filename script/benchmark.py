from datetime import datetime
import multiprocessing
import os
import subprocess
import time
import sys
import re



OUTDIR_HEAD = '~/MicSE/result_900/'


ADDR_30_Q = {
    'KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6': [
        (218, 24),
        (405, 24),
        (616, 20),
        (753, 20),
        (932, 24),
        (1074, 24),
        (1112, 30),
        (1270, 20),
        (1308, 20),
        (1572, 24),
    ],
    'KT1Ag29Dotu8iEigVrCARu7jmW5gkF1RyHUB': [
        (133, 16),
        (261, 12),
        (333, 16),
        (550, 16),
        (551, 16),
        (649, 20),
        (708, 20),
        (799, 24),
    ],
    'KT1AKNCvvGN8QEiL6bd8UHDXq4tmiNRsKYs9': [
        (26, 16),
        (117, 24),
        (172, 28),
        (1187, 32),
        (1195, 32),
        (1196, 32),
        (1197, 32),
        (1220, 32),
        (1221, 32),
        (1251, 32),
        (1252, 32),
        (1286, 16),
    ],
    'KT1ArrDG6dXqgvTH5RcyYFy4TmShG1MWajSr': [
        (1377, 16),
        (1378, 16),
    ],

    'KT1B2GSe47rcMCZTRk294havTpyJ36JbgdeB': [
        (624, 24),
        (1016, 28),
        (1340, 24),
        (1364, 24),
        (1465, 28),
    ],

    'KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV': [
        (83, 28),
        (112, 24),
        (149, 24),
        (153, 24),
        (157, 24),
        (188, 28),
        (224, 24),
        (1021, 24),
        (1035, 24),
    ],
    'KT1BZyfCcgMRb7gniyyM6iobEYVQc9vECGua': [
        (161, 28),
        (227, 24),
        (252, 24),
        (277, 24),
        (324, 24),
        (349, 24),
        (394, 24),
        (419, 24),
        (428, 24),
        (463, 24),
        (488, 24),
        (495, 24),
        (497, 24),
        (556, 28),
        (581, 28),
        (626, 28),
        (651, 28),
    ],

    'KT1C4rP4S7XeP5oVwZumxpR3hcxHSEN2MV9U': [
        (815, 31),
        (889, 31),
        (1259, 28),
    ],

    'KT1CT7S2b9hXNRxRrEcany9sak1qe4aaFAZJ': [
        (209, 24),
        (396, 24),
        (587, 20),
        (724, 20),
        (867, 24),
        (962, 24),
        (1000, 30),
        (1112, 20),
        (1150, 20),
        (1415, 24),
    ],
    'KT1DrJV8vhkdLEj76h1H9Q4irZDqAkMPo1Qf': [
        (206, 24),
        (393, 24),
        (584, 20),
        (721, 20),
        (889, 24),
        (1011, 24),
        (1049, 30),
        (1187, 20),
        (1225, 20),
        (1490, 24),
    ],
    'KT1Ep5RX2VVyP7zD3kYhEzJyJgfb8oBSUv2H': [
        (18, 12),
        (109, 20),
        (164, 24),
        (1179, 28),
        (1187, 28),
        (1188, 28),
        (1189, 28),
        (1212, 28),
        (1213, 28),
        (1243, 28),
        (1244, 28),
        (1277, 16),
    ],

    'KT1FEdxBE91HAuPvD3T41tnHgsrSZMBW3vsF': [
        (534, 24),
        (572, 28),
        (580, 28),
    ],

    'KT1GBmWKvbr4U15uGhvyLCiyaZif5i7AYeDY': [
        (1773, 20),
        (2985, 20),
        (2986, 20),
    ],

    'KT1GsdckBVCsgqp6ERYLnyawyXACAAQspPv6': [
        (844, 31),
        (918, 31),
        (1286, 31),
        (1485, 31),
    ],

    'KT1Hkg5qeNhfwpKW4fXvq7HGZB9z2EnmCCA9': [
        (248, 28),
        (380, 24),
        (414, 24),
        (522, 24),
        (624, 24),
        (633, 24),
        (723, 24),
        (730, 24),
        (732, 24),
        (859, 28),
        (961, 28),
    ],

    'KT1KeKqrvtMujUGdrkwxhtuyVSqNBHPZnoyt': [
        (343, 24),
        (556, 20),
        (682, 20),
        (792, 20),
        (856, 20),
        (982, 20),
        (1001, 20),
    ],

    'KT1Lrjm4rPcQNqQG5UVN2QvF1ouD9eDuFwbQ': [
        (83, 28),
        (112, 24),
        (149, 24),
        (153, 24),
        (157, 24),
        (188, 28),
        (224, 24),
        (1021, 24),
        (1035, 24),
    ],
    'KT1LXVbM8Lhf5HV3C5ebhQWp4H1rezMCfMKz': [
        (1675, 24),
        (3167, 28),
        (3168, 28),
    ],
    'KT1NM7a8r2u96y9pyH1aHfSa6TpQ23ZwdYsX': [
        (1353, 24),
        (1390, 24),
        (1400, 24),
        (1579, 24),
    ],
    'KT1NmoofGosSaWFKgAbt7AMTqnV1xfqeAhLT': [
        (238, 24),
        (930, 28),
        (1233, 31),
        (1254, 35),
        (1260, 35),
        (1275, 35),
        (1281, 35),
        (1319, 35),
        (1372, 35),
        (1402, 35),
        (1427, 35),
        (1456, 35),
        (1970, 24),
    ],


    'KT1PvZ8c77yAjwpomJuvY9DJm6AmCfSHxmdK': [
        (780, 31),
        (854, 31),
        (1225, 28),
    ],

    'KT1QaQSUUbBvoxb4sShbQxeUPv1ZyD5sX6ff': [
        (129, 24),
        (195, 24),
        (1158, 24),
        (1292, 28),
        (1308, 28),
        (1317, 28),
    ],
    'KT1R8wDzRrsTmqq6UykpSezTgwXU6VGnwHwc': [
        (174, 44),
        (463, 32),
        (490, 74),
    ],

    'KT1T1tZRqU7DuLf6qsMFxBFFXqLsAG3qhXxY': [
        (222, 28),
        (246, 28),
        (266, 28),
        (563, 35),
    ],


    'KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9': [
        (184, 40),
        (286, 89),
        (352, 36),
        (514, 44),
        (896, 36),
        (919, 36),
        (1059, 36),
        (1147, 36),
        (1386, 24),
    ],

    'KT1VemSYVVLsed4ejg1g3nfDkDUmW4rAN515': [
        (529, 24),
        (567, 28),
        (575, 28),
    ],


    'KT1WtkKhbN6yLBTcPt2TrCfkRthMW5uTHm2F': [
        (505, 24),
        (543, 28),
        (551, 28),
    ],
    'KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab': [
        (206, 24),
        (395, 24),
        (588, 20),
        (725, 20),
        (897, 24),
        (1021, 24),
        (1059, 30),
        (1202, 20),
        (1240, 20),
        (1511, 24),
    ],
    'KT18dDtdzvEj3Y9okKJxASMCyWfSscRfjtbP': [
        (210, 24),
        (399, 24),
        (612, 20),
        (749, 20),
        (934, 24),
        (1079, 24),
        (1117, 30),
        (1380, 24),
    ],
    'KT19TiuQRTNo4nsybpQQzunonJo1wAFdvRA5': [
        (147, 40),
        (443, 32),
        (470, 74),
    ]
}

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

def run(cmd):
    print(f'{datetime.now().strftime("%H:%M:%S")} : {cmd}', flush=True)
    os.system(cmd)
    return 0


if __name__ == '__main__':
    # first make directory storing result file
    argc = len(sys.argv)
    if argc < 3 or argc > 5:
        print("Usage: python3 benchmark.py <cores> <start idx> <end_idx> <output_dir>")
        print("Usage: python3 benchmark.py <cores> <target idx> <output_dir>")
        print("Usage: python3 benchmark.py <cores> <output_dir>")
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
        assert(start_idx <= end_idx and end_idx <= 207)
    elif argc == 4:
        start_idx, end_idx = int(sys.argv[2]), int(sys.argv[2])
        assert(end_idx <= 207)
    else:
        start_idx, end_idx = 1, 207
    
    # determine and check output_dir and sub result directory
    output_dir = sys.argv[-1]

    is_dir_exists = os.path.exists(output_dir)
    if is_dir_exists == False:
        print("Output Directory is not present")
        exit(1)

    result_dir = output_dir + "/result_900/"
    if os.path.exists(result_dir) == False:
        os.system(f"mkdir {result_dir}")
    for x in range(start_idx, end_idx + 1):
        if os.path.exists(f"{result_dir}/{x}") == False:
            os.system(f'mkdir {result_dir}/{x}')

    poolnum = cores


    with multiprocessing.Pool(processes=poolnum) as pool:
        IDX = 1
        for contract_addr, query_list in ADDR_30_Q.items():
            for query in query_list:
                # Run Twice in baseline and micse
                if IDX < start_idx:
                    IDX += 1
                    continue
                if IDX > end_idx:
                    break
                for binary, suffix in (("baseline", "nonco"), ("micse", "syner")):
                    # Run a command
                    while True:
                        # check running processes
                        psr = subprocess.run(
                            ['ps', '-e'], capture_output=True)
                        psr_output = psr.stdout.decode('utf-8').split()
                        if psr_output.count('timeout') < poolnum:
                            row, col = query
                            command = f"timeout 1000 {binary} -T 900 -d -q {row} {col} -I ~/vagrant/benchmarks/evaluation/{contract_addr}.tz -S ~/vagrant/benchmarks/evaluation/{contract_addr}.storage.tz > {result_dir}/{IDX}/{contract_addr}_{row}_{col}.{suffix} 2>&1 &"
                            pool.map(run, [command])
                            time.sleep(1)
                            break            
                        else:
                            time.sleep(10)
                IDX += 1
    print("[*] End of running all commands")

    while True:
        psr = subprocess.run(
            ['ps', '-e'], capture_output=True)
        psr_output = psr.stdout.decode('utf-8').split()
        if psr_output.count('timeout') > 0:
            time.sleep(10)
        else:
            break

    print("[*] End of Benchmarking")
    print("[*] Now Start to parse result and show table")

    import pandas as pd

    column_names = pd.DataFrame([["Contact Addr.", ""],
                                ["Baseline", "Result"],
                                ["Baseline", "Time(s)"],
                                ["MicSE", "Result"],
                                ["MicSE", "Time(s)"],
                                ["Speedup", ""]],
                                columns=["No.", ""])
    rows  = []
    idx = 1

    for contract_addr, query_list in ADDR_30_Q.items():
        for query in query_list:
            if idx >= start_idx and idx <= end_idx:
                qloc = query[0]
                row, col = qloc, query[1]
                resultpath = f"{result_dir}/{idx}/{contract_addr}_{row}_{col}.nonco"
                baseline_status, baseline_time_second = parse_result(resultpath)
                resultpath = f"{result_dir}/{idx}/{contract_addr}_{row}_{col}.syner"
                micse_status, micse_time_second = parse_result(resultpath)
                if type(baseline_time_second) == int:
                    speedup = "> " + str(round(baseline_time_second / micse_time_second, 1))
                else:
                    speedup = "> " + str(round(900 / micse_time_second, 1))
                row = [contract_addr, baseline_status, baseline_time_second, micse_status, micse_time_second, speedup]
                rows.append(row)

            idx += 1
    columns = pd.MultiIndex.from_frame(column_names)
    index = ["#" + str(i).rjust(2, "0") for i in range(start_idx, end_idx + 1)]

    df = pd.DataFrame(rows, columns=columns, index=index)
    print(df)

    
