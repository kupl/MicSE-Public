# Usage of MicSE

## Table of Contents

- [Usage of MicSE](#usage-of-micse)
  - [Table of Contents](#table-of-contents)
  - [Run](#run)
    - [MicSE](#micse)
      - [MicSE Example](#micse-example)
    - [MicSE Prover](#micse-prover)
      - [MicSE Prover Example](#micse-prover-example)
    - [MicSE Refuter](#micse-refuter)
      - [MicSE Refuter Example](#micse-refuter-example)
  - [Specifying Custom Safety Properties](#specifying-custom-safety-properties)
    - [Custom Safety Property Example](#custom-safety-property-example)
  - [MicSE for High Level Language](#micse-for-high-level-language-eg-cameligo-smartpy)
    - [micse_taq.sh](#micse_taqsh)
    - [micse_taq.sh example](#micse_taqsh-example)

## Run

Binary execution files are located at `(PROJECT_DIR)/bin` directory.

- `micse-s`: Run whole MicSE for input Michelson program code
- `micse.naive_trxpath_main`: Run MicSE without cooperation

### MicSE

```bash
$ (PROJECT_DIR)/bin/micse-s -I (FILE_PATH) -S (FILE_PATH) ...
 Final-Report : 
=== Final Result ===
Time: _ sec   Memory: _ GB
Combinations: _
#Total: _   #Proved: _    #Refuted: _   #Failed: _
#Err: _ #UU: _  #UF: _  #FU: _  #FF: _
<< Proved >>
...

<< Refuted >>
...

<< Failed >>
...
```

- **Input(Parameters):**
  - `--input`, `-I`: The file path of input Michelson code. (REQUIRED)
    - (Optionally) with [User custom safety property](#user-custom-safety-property)
  - `--initial-storage`, `-S`: The file path of initial storage information that the target contract has. (REQUIRED)
  - `--memory-bound`, `-M`: The memory budget for overall MicSE process in GB. (default: 5GB)
  - `--total-timeout`, `-T`: The time budget for overall MicSE process in seconds. (default: 360sec)
  - `--z3-timeout`, `-Z`: The time budget for Z3 solver in seconds. (default: 30sec)
  - `--path-limit`, `-P`: The length limit of the unrolled path in a single transaction. (default: 5)
  - `--query-pick`, `-q`: Line and column number of a specified target query in an integer pair.
  - `--verbose`, `-v`: Verbose logging mode.
- **Output:**
  - Verification result from the MicSE

### MicSE example

- **Input:** [KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab.tz](../benchmarks/top30/KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab.tz)
- **Output:**
```txt
$ micse-s -I KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab.tz -S KT1Xf2Cwwwh67Ycu7E9yd3UhsABQC4YZPkab.storage.tz
 Final-Report : 
=== Final Result ===
Time: 137.136473 sec            Memory: 0.068417 GB
Combinations: 17
#Total: 10              #Proved: 10             #Refuted: 0             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>
> Location:(CCLOC_Pos((lin 206)(col 24))((lin 206)(col 27)))
        Category:Q_mutez_add_no_overflow

> Location:(CCLOC_Pos((lin 395)(col 24))((lin 395)(col 27)))
        Category:Q_mutez_add_no_overflow

> Location:(CCLOC_Pos((lin 588)(col 20))((lin 588)(col 23)))
        Category:Q_mutez_mul_mnm_no_overflow

> Location:(CCLOC_Pos((lin 725)(col 20))((lin 725)(col 23)))
        Category:Q_mutez_sub_no_underflow

> Location:(CCLOC_Pos((lin 897)(col 24))((lin 897)(col 27)))
        Category:Q_mutez_add_no_overflow

> Location:(CCLOC_Pos((lin 1021)(col 24))((lin 1021)(col 27)))
        Category:Q_mutez_mul_mnm_no_overflow

> Location:(CCLOC_Pos((lin 1059)(col 30))((lin 1059)(col 33)))
        Category:Q_mutez_sub_no_underflow

> Location:(CCLOC_Pos((lin 1202)(col 20))((lin 1202)(col 23)))
        Category:Q_mutez_mul_mnm_no_overflow

> Location:(CCLOC_Pos((lin 1240)(col 20))((lin 1240)(col 23)))
        Category:Q_mutez_sub_no_underflow

> Location:(CCLOC_Pos((lin 1511)(col 24))((lin 1511)(col 27)))
        Category:Q_mutez_add_no_overflow

<< Refuted >>

<< Failed >>

```



### MicSE Prover

```bash
$ (PROJECT_DIR)/bin/micse.naive_prover -I (FILE_PATH) -S (FILE_PATH) ...
 Final-Report : 
=== Final Result ===
Time: _ sec   Memory: _ GB
Combinations: _
#Total: _   #Proved: _    #Refuted: _   #Failed: _
#Err: _ #UU: _  #UF: _  #FU: _  #FF: _
<< Proved >>
...

<< Refuted >>
...

<< Failed >>
...
```

- **Input(Parameters):**
  - `--input`, `-I`: The file path of input Michelson code. (REQUIRED)
    - (Optionally) with [User custom safety property](#user-custom-safety-property)
  - `--initial-storage`, `-S`: The file path of initial storage information that the target contract has. (REQUIRED)
  - `--z3-timeout`, `-Z`: The time budget for Z3 solver in seconds. (default: 30sec)
  - `--path-limit`, `-P`: The length limit of the unrolled path in a single transaction. (default: 5)
  - `--query-pick`, `-q`: Line and column number of a specified target query in an integer pair.
  - `--verbose`, `-v`: Verbose logging mode.
- **Output:**
  - Verification result from the MicSE

#### MicSE Prover Example

- **Demo Video:** [Link](https://youtu.be/fZqFA1HcRNw)
- **Input:** [`deposit.tz`](../benchmarks/examples/deposit.tz)
- **Output:**

```txt
$ ./bin/micse.naive_prover -I ./benchmarks/examples/deposit.tz -S ./benchmarks/examples/deposit.storage.tz -q 126 29
  Final-Report : 
=== Final Result ===
Time: 120.732395 sec    Memory: 0.031319 GB
Combinations: 1948
#Total: 1   #Proved: 1    #Refuted: 0   #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>
> Location:(CCLOC_Pos((lin 126)(col 29))((lin 126)(col 32)))
  Category:Q_mutez_sub_no_underflow

<< Refuted >>

<< Failed >>
```

### MicSE Refuter

```bash
$ (PROJECT_DIR)/bin/micse.advanced_trxpath_refuter -I (FILE_PATH) -S (FILE_PATH) ...
 Final-Report : 
=== Final Result ===
Time: _ sec   Memory: _ GB
Combinations: _
#Total: _   #Proved: _    #Refuted: _   #Failed: _
#Err: _ #UU: _  #UF: _  #FU: _  #FF: _
<< Proved >>
...

<< Refuted >>
...

<< Failed >>
...
```

- **Input(Parameters):**
  - `--input`, `-I`: The file path of input Michelson code. (REQUIRED)
    - (Optionally) with [User custom safety property](#user-custom-safety-property)
  - `--initial-storage`, `-S`: The file path of initial storage information that the target contract has. (REQUIRED)
  - `--z3-timeout`, `-Z`: The time budget for Z3 solver in seconds. (default: 30sec)
  - `--path-limit`, `-P`: The length limit of the unrolled path in a single transaction. (default: 5)
  - `--query-pick`, `-q`: Line and column number of a specified target query in an integer pair.
  - `--verbose`, `-v`: Verbose logging mode.
- **Output:**
  - Refuting result from the MicSE

#### MicSE Refuter Example

- **Demo Video:** [Link](https://youtu.be/DAwGzTtootc)
- **Input:** [`deposit.tz`](../benchmarks/examples/deposit.tz)
- **Output:**

```txt
$ ./bin/micse.advanced_trxpath_refuter -I ./benchmarks/examples/deposit.tz -S ./benchmarks/examples/deposit.storage.tz -q 344 22
 Final-Report : 
=== Final Result ===
Time: 23.511754 sec   Memory: 0.039196 GB
Combinations: 0
#Total: 1   #Proved: 0    #Refuted: 1   #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>

<< Refuted >>
> Location:(CCLOC_Pos((lin 344)(col 22))((lin 344)(col 52)))
  Category:Q_assertion
  Refuted Path:
    - Initial Balance: 0
    - Transaction #1:
      Amount:0
      Parameter:
        (|(const_or_right (Or (Or Int Int) (Or Unit Unit)))|
          (|(const_or_right (Or Unit Unit))| (|(const_or_left Unit)| const_unit)))
    - Transaction #2:
      Amount:0
      Parameter:
        (|(const_or_left (Or (Or Unit Unit) (Or (Or Address (Option Address)) (Or Address Unit))))|
          (|(const_or_left (Or Unit Unit))| (|(const_or_left Unit)| const_unit)))
    - Transaction #3:
      Amount:0
      Parameter:
        (|(const_or_right (Or (Or Int Int) (Or Unit Unit)))|
          (|(const_or_left (Or Int Int))| (|(const_or_left Int)| 9223372036854775769)))
    - Transaction #4:
      Amount:0
      Parameter:
        (|(const_or_right (Or (Or Int Int) (Or Unit Unit)))|
          (|(const_or_right (Or Unit Unit))| (|(const_or_right Unit)| const_unit)))

<< Failed >>

```

## Specifying Custom Safety Properties

Given a Michelson program without any annotations, MicSE basically attemps to verify the absence of arithmetic overflow.
However, MicSE also supports verification of custom safety properties using the **`#__MICSE_CHECK {(instruction)}`** statement, where **instruction** denotes arbitrary Michelson instructions that produce boolean values. That is, for each user-provided assertion, MicSE attempts to prove that the top of the stack is the true value.
The **`#__MICSE_CHECK {(instruction)}`** statement should be given as a single-line comment. An example usage is given below.

### Custom Safety Property Example

The example in below is located at [here](../benchmarks/examples/transfer.tz)

``` michelson
parameter (pair (address %receiver) (mutez %value));
storage   (pair (map %balance address mutez) (mutez %totalSupply));
code { 
  UNPAIR; UNPAIR; DIP 2 { UNPAIR };
        # %receiver :: %value :: %balance :: %totalSupply :: []

  DUP 3; SENDER; GET; IF_NONE { FAIL } {};
        # %balance[@sender] :: %receiver :: %value :: %balance :: %totalSupply :: []

  DUP 3; DUP 2; COMPARE; GE; IF {} { FAIL };
        # %balance[@sender] :: %receiver :: %value :: %balance :: %totalSupply :: []

  DIP { DIG 2; DUP 3 }; SUB; SOME; SENDER; UPDATE;
        # %balance' :: %receiver :: %value :: %totalSupply :: []

  DUP; DUP 3; GET; IF_NONE { PUSH mutez 0 } {};
        # %balance'[%receiver] :: %balance' :: %receiver :: %value :: %totalSupply :: []

  DIP { DIG 2 }; ADD;
        # (%balance'[%receiver] + %value) :: %balance' :: %receiver :: %totalSupply :: []


  # [The user-provided assertion below should be a single-line comment]
  #__MICSE_CHECK { \
    DIP {DROP; DROP }; \
        # (%balance'[%receiver] + %value) :: %totalSupply :: []

    COMPARE; \
        # int :: []

    LE };
        # bool :: []
  # [This notation should be in only one line]
        # (%balance'[%receiver] + %value) :: %balance' :: %receiver :: %totalSupply :: []


  SOME; DIG 2; UPDATE;
        # %balance'' :: %totalSupply :: []
  PAIR; NIL operation; PAIR };
        # (pair [] (pair %balance'' %totalSupply)) :: []
```

- **Input:** [`transfer.tz`](../benchmarks/examples/transfer.tz)
- **Output:**

```txt
$ ./bin/micse.naive_prover -I ./benchmarks/examples/transfer.tz -S ./benchmarks/examples/transfer.storage.tz
 Final-Report : 
=== Final Result ===
Time: 0.611170 sec              Memory: 0.024593 GB
Combinations: 1
#Total: 3               #Proved: 3              #Refuted: 0             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>
> Location:(CCLOC_Pos((lin 7)(col 25))((lin 7)(col 28)))
        Category:Q_mutez_sub_no_underflow

> Location:(CCLOC_Pos((lin 9)(col 18))((lin 9)(col 21)))
        Category:Q_mutez_add_no_overflow

> Location:(CCLOC_Pos((lin 11)(col 4))((lin 11)(col 52)))
        Category:Q_assertion

<< Refuted >>

<< Failed >>
```

## MicSE for high level language (e.g. cameLigo, SmartPy)

If you want to test MicSE for high level language, you can test it with `script/micse_taq.sh` which automatically compile cameligo or smartpy into michelson language and run it with MicSE

### micse_taq.sh

```bash
$ (PROJECT_DIR)/script/micse_taq.sh -C [mligo|smartpy] -I (FILE_PATH) -S (FILE_PATH) ...
 Final-Report : 
=== Final Result ===
Time: _ sec   Memory: _ GB
Combinations: _
#Total: _   #Proved: _    #Refuted: _   #Failed: _
#Err: _ #UU: _  #UF: _  #FU: _  #FF: _
<< Proved >>
...

<< Refuted >>
...

<< Failed >>
...
```

- **Input(Parameters):**
  -
  - `-I`: The file path of input [mligo|SmartPy] code. file name convention is `<contract name>.[mligo|py]`(REQUIRED)
  - `-S`: The file path of initial storage information that the target contract has. name convention is `<contract name>.storageList.mligo` (REQUIRED only for cameligo)
  - `-M`: The memory budget for overall MicSE process in GB. (default: 5GB)
  - `-T`: The time budget for overall MicSE process in seconds. (default: 360sec)
  - `-C`: The file is cameligo or SmartPy
  - `-m`: Mode of MicSE (default: non-cooperation mode -> run with micse.naive_trxpath_main)
  - `-h`: displays the option
- **Output:**
  - Verification result from the MicSE

### micse_taq.sh example

- **Input:** [hashchall.mligo](../benchmarks/ligo/hashchall.mligo)
- **Output:**
```txt
$ script/micse_taq.sh -C mligo -I benchmarks/ligo/hashchall.mligo -S benchmarks/ligo/hashchall.storageList.mligo 
Initializing taqueria is done
Note: parameter file associated with "hashchall.mligo" can't be found, so "hashchall.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

Compile process is done
 Final-Report : 
=== Final Result ===
Time: 1.972934 sec              Memory: 0.031784 GB
Combinations: 3
#Total: 1               #Proved: 0              #Refuted: 1             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>

<< Refuted >>
> Location:(CCLOC_Pos((lin 55)(col 19))((lin 55)(col 22)))
        Category:Q_mutez_add_no_overflow
        Refuted Path:
                - Initial Balance: 0
                - Transaction #1:
                        Amount:0
                        Parameter:
                                (|(const_or_left (Pair Int Bytes))|
                                  (|(const_pair Int Bytes)| 9223372036812775808 const_bytes_nil))
                - Transaction #2:
                        Amount:0
                        Parameter:
                                (let ((a!1 (|(const_pair (Pair Address Bytes) (Lambda Unit (List Operation)))|
                                             (|(const_pair Address Bytes)|
                                               (|(const_address KeyHash)| (|(const_keyhash_str String)| "!0!"))
                                               const_bytes_nil)
                                             (|(const_lambda Unit (List Operation))| const_unit nil))))
                                  (|(const_or_right (Pair (Pair Address Bytes) (Lambda Unit (List Operation))))|
                                    a!1))

<< Failed >>

```
