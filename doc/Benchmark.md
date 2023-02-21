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
06:29:59 : timeout 1000 baseline -T 900 -d -q 83 28 -I ~/vagrant/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.tz -S ~/vagrant/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.storage.tz > .//result_900/8/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.nonco 2>&1 &
06:30:29 : timeout 1000 micse -T 900 -d -q 83 28 -I ~/vagrant/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.tz -S ~/vagrant/benchmarks/evaluation/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.storage.tz > .//result_900/8/KT1BzkCjvNf4tgPjPHMNFTfe2UpU1JzCrXiV.syner 2>&1 &
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
```