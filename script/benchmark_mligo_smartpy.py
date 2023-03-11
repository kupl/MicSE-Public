# python3 benchmark_mligo.py <output_dir>
from datetime import datetime
import multiprocessing
import os
import subprocess
import time
import re
import sys

mligo_benchmark_list = {
    "Increment": [],
    "FA1": [],
    "hashchall": [],
    "ID": [],
    "raffle": [],
    "taco-shop": []
}
smartpy_benchmark_list = {
    "increment": [],
    "FA1": [],
    "hashchall": [],
    "ID": [],
    "raffle": [],
    "taco-shop": []
}

PROJECT_DIR = "~/MicSE-Public/"

OUTPUT_DIR = f"{PROJECT_DIR}/benchmarks/benchmark_result"

def run(cmd):
    # print current datetime and execute command parameter
    print(f'{datetime.now().strftime("%H:%M:%S")} : {cmd}', flush=True)
    os.system(cmd)
    return 0

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

if __name__ == "__main__":
    argc = len(sys.argv)
    if argc != 3:
        print("Usage: python3 benchmark_mligo.py <output_dir_name> [mligo|smartpy]")
        exit(1)


    is_dir_exists = os.path.exists(sys.argv[1])
    if is_dir_exists == True:
        print("Please check output_dir is not present")
        exit(1)
    code_format = sys.argv[2]
    if code_format != "mligo" and code_format != "smartpy":
        print("Usage: python3 benchmark_mligo.py <output_dir_name> [mligo|smartpy]")
        exit(1)

    OUTPUT_DIR = os.path.abspath(sys.argv[1])
    os.system(f"mkdir {OUTPUT_DIR}")
    os.chdir(OUTPUT_DIR)
    print(f"[*] Working Directory : {os.getcwd()}")

    # make new directory
    # init taqueria
    os.system("taq init ./")
    os.mkdir("./result")
    if code_format == "mligo":
        os.system("taq install @taqueria/plugin-ligo >/dev/null")
        suffix = "mligo"
        benchmark_list = mligo_benchmark_list
        total_nums = 9
    else:
        os.system("taq install @taqueria/plugin-smartpy >/dev/null")
        suffix = "py"
        benchmark_list = smartpy_benchmark_list
        total_nums = 10

    import pandas as pd

    column_names = pd.DataFrame([["Contract Name.", ""],
                                ["QLoc", "Row"],
                                ["QLoc", "Column"],
                                ["MicSE", "Result"],
                                #["MicSE", "Time(s)"],
                                ],
                                columns=["No.", ""])
    rows  = []
    #idx = 1


    for benchmark_name, query_locs_list in benchmark_list.items():
        if code_format == "mligo":
            file_name = f"{PROJECT_DIR}/benchmarks/ligo/{benchmark_name}.{suffix}"
            storage_name = f"{PROJECT_DIR}/benchmarks/ligo/{benchmark_name}.storageList.{suffix}"
            # copy target files to working direcotry
            os.system(f"cp {file_name} {storage_name} {OUTPUT_DIR}/contracts/")
            #os.system(f"{PROJECT_DIR}/script/micse_taq.sh -C mligo -I {file_name} -S {storage_name} -m syner > {OUTPUT_DIR}/{benchmark_name}")
            # change current working directory
            # compile target
            os.system(f"ligo compile contract ./contracts/{benchmark_name}.{suffix} > artifacts/{benchmark_name}.tz")
            with open(f"./contracts/{benchmark_name}.storageList.{suffix}", "rt") as f:
                storage_content = f.read()
                idx = storage_content.index('=') + 1
                storage_expr = f"'{storage_content[idx:]}'"
                os.system(f"ligo compile storage contracts/{benchmark_name}.{suffix} {storage_expr} >artifacts/{benchmark_name}.default_storage.tz")
        else:
            file_name = f"{PROJECT_DIR}/benchmarks/smartpy/{benchmark_name}.{suffix}"
            # copy target files to working direcotry
            os.system(f"cp {file_name} {OUTPUT_DIR}/contracts/")
            #os.system(f"{PROJECT_DIR}/script/micse_taq.sh -C mligo -I {file_name} -S {storage_name} -m syner > {OUTPUT_DIR}/{benchmark_name}")
            # change current working directory
            # compile target
            os.system(f"taq compile {benchmark_name}.{suffix} >/dev/null")
        popen = subprocess.Popen(f'dune exec -- get_query_locs -I ./artifacts/{benchmark_name}.tz', stdout=subprocess.PIPE, stderr=subprocess.PIPE,shell=True)
        (result, _stderr_data) = popen.communicate()
        result_list = result.split(b"\n")[:-1]
        for result in result_list:
            qloc = list(map(int, result.split(b" ")[1:]))
            query_locs_list.append(qloc)

        # run micse for each query
        for query_loc in query_locs_list:
            row, col = query_loc
            result_file_path = os.path.abspath(f"./result/{benchmark_name}_{suffix}_{row}_{col}.result")
            run(f"micse -q {row} {col} -I artifacts/{benchmark_name}.tz -S artifacts/{benchmark_name}.default_storage.tz > {result_file_path}")
            status, running_time_second = parse_result(result_file_path)

            row = [f"{benchmark_name}.{suffix}", row, col, status]
            rows.append(row)


    columns = pd.MultiIndex.from_frame(column_names)

    index = ["#" + str(i).rjust(2, "0") for i in range(1, total_nums + 1)]

    df = pd.DataFrame(rows, columns=columns, index=index)
    print(df)
