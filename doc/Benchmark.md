# Benchmark of MicSE

## 1. Benchmark in Paper

You can test and reproduce result of experiment in our paper. In `script/` folder, we prepare script for automatically testing our tool. \<start idx> and \<end idx> are same in our paper. (idx range: 1 ~ 30)

- how to check usage

```bash
$ python3 table2.py
Usage: python3 table2.py <cores> <start idx> <end_idx> <output_dir>
Usage: python3 table2.py <cores> <target idx> <output_dir>
Usage: python3 table2.py <cores> <output_dir> # test all queries
```

- how to run script

```bash
$ python3 table2.py 2 8 ./
06:29:59 : timeout 1000 baseline -T 900 -d -q 83 28 -I (PROJECT_DIR)/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.tz -S (PROJECT_DIR)/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.storage.tz > ./result_900/8/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.nonco 2>&1 &
06:30:29 : timeout 1000 micse -T 900 -d -q 83 28 -I (PROJECT_DIR)/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.tz -S (PROJECT_DIR)/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.storage.tz > ./result_900/8/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.syner 2>&1 &
[*] End of Benchmarking
[*] Now Start to parse result and show table in paper

No.                         Contact Addr.  Inst QLoc Baseline           MicSE         Speedup
                                                       Result Time(s)  Result Time(s)
#08  KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV  1477   83   Proved     106  Proved      19   > 5.6
```

## 2. Benchmark testing all queries

You can also test all queries contained in `.tz` files in `benchmarks/evaluation/`. We prepare script `script/benchmark.py`, whose usage is same as above script `script/table2.py`. Idx range is from 1 to 207

- how to use script

```bash
$ python3 benchmark.py  4 1 ./
10:02:14 : timeout 1000 baseline -T 900 -d -q 218 24 -I (PROJECT_DIR)/benchmarks/evaluation/KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6.tz -S (PROJECT_DIR)/benchmarks/evaluation/KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6.storage.tz > ./result_900/1/KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6_218_24.nonco 2>&1 &
10:02:15 : timeout 1000 micse -T 900 -d -q 218 24 -I (PROJECT_DIR)/benchmarks/evaluation/KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6.tz -S (PROJECT_DIR)/benchmarks/evaluation/KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6.storage.tz > ./result_900/1/KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6_218_24.syner 2>&1 &
[*] End of running all commands
[*] End of Benchmarking
[*] Now Start to parse result and show table
No.                         Contact Addr. Baseline           MicSE         Speedup
                                            Result Time(s)  Result Time(s)
#01  KT1AbYeDbjjcAnV1QK7EZUUdqku77CdkTuv6   Failed     T/O  Proved     441   > 2.0
```

## 3. Benchmark testing of mligo and smartpy

We prepare scripts for automatically testing cameligo, smartpy source codes, whose path is `script/benchmark_mligo_smartpy`.

- how to use script

```bash
# check usage
$ python3 benchmark_mligo_smartpy.py
Usage: python3 benchmark_mligo.py <output_dir_name> [mligo|smartpy]

# don't use existing directory name
$ python3 benchmark_mligo_smartpy.py test # already existing directory name
Usage: python3 benchmark_mligo.py <output_dir_name> [mligo|smartpy]

# test all mligo benchmarks
$ python3 benchmark_mligo_smartpy.py no_existing_dir_name mligo
[*] Working Directory : (PROJECT_DIR)/script/no_existing_dir_name
Project taq'ified!
Note: parameter file associated with "Increment.mligo" can't be found, so "Increment.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

08:31:32 : micse -q 20 18 -I artifacts/Increment.tz -S artifacts/Increment.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/Increment_mligo_20_18.result
08:31:35 : micse -q 21 18 -I artifacts/Increment.tz -S artifacts/Increment.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/Increment_mligo_21_18.result
Note: parameter file associated with "FA1.mligo" can't be found, so "FA1.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

08:31:44 : micse -q 65 14 -I artifacts/FA1.tz -S artifacts/FA1.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/FA1_mligo_65_14.result
08:31:47 : micse -q 79 14 -I artifacts/FA1.tz -S artifacts/FA1.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/FA1_mligo_79_14.result
Note: parameter file associated with "hashchall.mligo" can't be found, so "hashchall.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

08:31:53 : micse -q 55 19 -I artifacts/hashchall.tz -S artifacts/hashchall.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/hashchall_mligo_55_19.result
Note: parameter file associated with "ID.mligo" can't be found, so "ID.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

08:31:58 : micse -q 53 18 -I artifacts/ID.tz -S artifacts/ID.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/ID_mligo_53_18.result
08:32:02 : micse -q 73 18 -I artifacts/ID.tz -S artifacts/ID.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/ID_mligo_73_18.result
Note: parameter file associated with "raffle.mligo" can't be found, so "raffle.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

08:32:13 : micse -q 34 18 -I artifacts/raffle.tz -S artifacts/raffle.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/raffle_mligo_34_18.result
Note: parameter file associated with "taco-shop.mligo" can't be found, so "taco-shop.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

08:33:26 : micse -q 42 10 -I artifacts/taco-shop.tz -S artifacts/taco-shop.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/taco-shop_mligo_42_10.result
No.   Contract Name. QLoc           MicSE
                      Row Column   Result
#01  Increment.mligo   20     18   Proved
#02  Increment.mligo   21     18  Refuted
#03        FA1.mligo   65     14  Refuted
#04        FA1.mligo   79     14  Refuted
#05  hashchall.mligo   55     19  Refuted
#06         ID.mligo   53     18  Refuted
#07         ID.mligo   73     18  Refuted
#08     raffle.mligo   34     18  Refuted
#09  taco-shop.mligo   42     10   Proved



# test all smartpy benchmarks
$ python3 benchmark_mligo_smartpy.py no_existing_dir_name mligo
[*] Working Directory : (PROJECT_DIR)/script/no_existing_dir_name
Project taq'ified!
08:34:23 : micse -q 33 9 -I artifacts/increment.tz -S artifacts/increment.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/increment_py_33_9.result
08:34:24 : micse -q 38 9 -I artifacts/increment.tz -S artifacts/increment.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/increment_py_38_9.result
08:34:28 : micse -q 71 5 -I artifacts/FA1.tz -S artifacts/FA1.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/FA1_py_71_5.result
08:34:30 : micse -q 94 5 -I artifacts/FA1.tz -S artifacts/FA1.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/FA1_py_94_5.result
08:34:35 : micse -q 65 13 -I artifacts/hashchall.tz -S artifacts/hashchall.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/hashchall_py_65_13.result
08:34:38 : micse -q 44 13 -I artifacts/ID.tz -S artifacts/ID.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/ID_py_44_13.result
08:34:41 : micse -q 70 13 -I artifacts/ID.tz -S artifacts/ID.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/ID_py_70_13.result
08:34:49 : micse -q 37 9 -I artifacts/raffle.tz -S artifacts/raffle.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/raffle_py_37_9.result
08:36:09 : micse -q 104 9 -I artifacts/raffle.tz -S artifacts/raffle.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/raffle_py_104_9.result
08:37:51 : micse -q 138 5 -I artifacts/taco-shop.tz -S artifacts/taco-shop.default_storage.tz > (PROJECT_DIR)/script/no_existing_dir_name/result/taco-shop_py_138_5.result
No. Contract Name. QLoc           MicSE
                    Row Column   Result
#01   increment.py   33      9   Proved
#02   increment.py   38      9  Refuted
#03         FA1.py   71      5   Proved
#04         FA1.py   94      5   Proved
#05   hashchall.py   65     13  Refuted
#06          ID.py   44     13  Refuted
#07          ID.py   70     13  Refuted
#08      raffle.py   37      9  Refuted
#09      raffle.py  104      9   Proved
#10   taco-shop.py  138      5   Proved
```
