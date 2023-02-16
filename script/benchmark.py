from datetime import datetime
import multiprocessing
import os
import subprocess
import time


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


OUTDIR_HEAD = '~/vagrant/benchmarks/result_900/'


def run(cmd):
    # print current datetime and execute command parameter
    print(f'{datetime.now().strftime("%H:%M:%S")} : {cmd}', flush=True)
    os.system(cmd)
    return 0

BINARY_SUFFIX = [("micse", "syner"), ("baseline", "nonco")]

if __name__ == '__main__':
    # first make directory storing result file

    os.system(f"mkdir {OUTDIR_HEAD}")
    for x in range(1, 31):
        os.system(f'mkdir {OUTDIR_HEAD}{x}')

    poolnum = 14
    #poolnum = ((multiprocessing.cpu_count()-1) or 1)

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
                            row, col = contract_info[idx][0], contract_info[idx][1]
                            contract_addr = contract_info[0]
                            command = f"timeout 1000 {binary} -T 900 -d -q {row} {col} -I ~/vagrant/benchmarks/evaluation/{contract_addr}.tz -S ~/vagrant/benchmarks/evaluation/{contract_addr}.storage.tz > ~/vagrant/benchmarks/result_900/{NUM}/{contract_addr}.{suffix} 2>&1 &"
                            pool.map(run, [command])
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

