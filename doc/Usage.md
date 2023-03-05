# Usage of MicSE

## Table of Contents

- [Usage of MicSE](#usage-of-micse)
  - [Table of Contents](#table-of-contents)
  - [Demo Videos](#demo-videos)
  - [Run](#run)
    - [MicSE](#micse)
    - [MicSE example](#micse-example)
  - [Specifying Custom Safety Properties](#specifying-custom-safety-properties)
    - [Custom Safety Property Example](#custom-safety-property-example)
  - [MicSE for high level language (e.g. Ligo, SmartPy)](#micse-for-high-level-language-eg-ligo-smartpy)
    - [micse\_taq.sh](#micse_taqsh)
    - [micse\_taq.sh example with cameligo](#micse_taqsh-example-with-cameligo)
    - [micse\_taq.sh example with pascaligo](#micse_taqsh-example-with-pascaligo)
    - [micse\_taq.sh example with SmartPy](#micse_taqsh-example-with-smartpy)

## Demo Videos

- MicSE evaluation example videos
  - [`KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9`: MicSE proves no overflow occured at line 184](https://youtu.be/9vcQNYH5mk0)
  - [`KT1Lrjm4rPcQNqQG5UVN2QvF1ouD9eDuFwbQ`: MicSE finds an overflow scenario](https://youtu.be/FxluWYiWlBI)
- Custom safety property example video
  - [`figure3`: Prove/Refute custom safety property](https://youtu.be/dZiDRjDSKeo)
- MicSE for high-level language example videos
  - [Example for CameLIGO](https://www.youtube.com/watch?v=82sX6M05S9E&list=PLNnGLFV5qy0pRvcu1mg2sGBE-DKNSrB9A&index=6)
  - [Example for PascaLIGO](https://www.youtube.com/watch?v=-y3Ebn2Mydc&list=PLNnGLFV5qy0pRvcu1mg2sGBE-DKNSrB9A&index=5)
  - [Example for SmartPy](https://www.youtube.com/watch?v=z2-M9gnoVek&list=PLNnGLFV5qy0pRvcu1mg2sGBE-DKNSrB9A&index=4)

## Run

Binary execution files are located at `(PROJECT_DIR)/bin` directory.

- `micse`: Run whole MicSE for input Michelson program code
- `baseline`: Run MicSE without cooperation

### MicSE

```bash
$ micse -I (FILE_PATH) -S (FILE_PATH) ...
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
    - (Optionally) with [Custom Safety Property Example](#custom-safety-property-example)
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

- **Input:** [KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9.tz](../benchmarks/evaluation/KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9.tz)
- **Output:**

```txt
$ micse -I (PROJECT_DIR)/benchmarks/evaluation/KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9.tz -S (PROJECT_DIR)/benchmarks/evaluation/KT1Tvr6XRUwN4JRjma1tsdVQ1GC6QU6gbsg9.storage.tz -q 184 40 -T 900
 Final-Report :
=== Final Result ===
Time: 297.485055 sec            Memory: 0.071789 GB
Combinations: 12
#Total: 1               #Proved: 1              #Refuted: 0             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>
> Location:(CCLOC_Pos((lin 184)(col 40))((lin 184)(col 43)))
        Category:Q_mutez_add_no_overflow

<< Refuted >>

<< Failed >>

```

- If MicSE is installed using installation script we provide (_vagrant box_, _docker image_, and _direct installation_), the micse binary file will be located at `~/MicSE-Public/bin/`.
- If MicSE is manually built using `dune build` command, the micse binary file `micse.exe` will be located at `(PROJECT_DIR)/_build/default/cmd/micse.exe`.

## Specifying Custom Safety Properties

Given a Michelson program without any annotations, MicSE basically attemps to verify the absence of arithmetic overflow.
However, MicSE also supports verification of custom safety properties using the **`#__MICSE_CHECK {(instruction)}`** statement, where **instruction** denotes arbitrary Michelson instructions that produce boolean values. That is, for each user-provided assertion, MicSE attempts to prove that the top of the stack is the true value.
The **`#__MICSE_CHECK {(instruction)}`** statement should be given as a single-line comment. An example usage is given below.

### Custom Safety Property Example

The example in below is located at [here](../benchmarks/tool_usage/figure3.tz)

``` michelson
{ parameter (or (unit %increase) (int %setv)) ;
  storage int ;   # Initial Storage Value Input: 49
  code {
    UNPAIR ;
    IF_LEFT {
      DROP ; PUSH int 1 ; SWAP ; SUB ; LEFT int ;
      LOOP_LEFT {
        PUSH int 50 ; DUP 2 ; COMPARE ; LT ;
        IF { PUSH int 1 ; ADD ; LEFT int } { RIGHT int } };
      # [The user-provided assertion below should be a single-line comment]
      #__MICSE_CHECK { PUSH int 50 ; DUP 2 ; COMPARE ; LE };
    }
    { PUSH int 50 ; DUP 2 ; COMPARE ; LT ;
      IF { SWAP ; DROP } { DROP } } ;
    NIL operation ; PAIR } }
```

- **Input:** [`figure3_safe.tz`](../benchmarks/tool_usage/figure3.tz)
- **Output:**

```txt
$ micse -I (PROJECT_DIR)/benchmarks/tool_usage/figure3_safe.tz -S (PROJECT_DIR)/benchmarks/tool_usage/figure3.storage.tz
 Final-Report :
=== Final Result ===
Time: 1.498865 sec              Memory: 0.033646 GB
Combinations: 11
#Total: 1               #Proved: 1              #Refuted: 0             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>
> Location:(CCLOC_Pos((lin 10)(col 8))((lin 10)(col 60)))
        Category:Q_assertion

<< Refuted >>

<< Failed >>

```

## MicSE for high level language (e.g. Ligo, SmartPy)

If you want to test MicSE for high level language, you can test it with `script/micse_taq.sh` which automatically compile cameligo or smartpy into michelson language and run it with MicSE

### micse_taq.sh

```bash
$ (PROJECT_DIR)/script/micse_taq.sh -C [mligo|ligo|religo|jsligo|smartpy] -I (FILE_PATH) -S (FILE_PATH) ...
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
  - `-I`: The file path of input [mligo|ligo|religo|jsligo|SmartPy] code. file name convention is `<contract name>.[mligo|ligo|jsligo|religo|py]`(REQUIRED)
  - `-S`: The file path of initial storage information that the target contract has. name convention is `<contract name>.storageList.[mligo|ligo|jsligo|religo]` (REQUIRED only for Ligo)
  - `-M`: The memory budget for overall MicSE process in GB. (default: 5GB)
  - `-T`: The time budget for overall MicSE process in seconds. (default: 360sec)
  - `-C`: The file is cameligo or pascaligo or jsligo or reasonligo or SmartPy
  - `-m`: Mode of MicSE (nonco -> run .tz with baseline, syner(default) -> run .tz with micse)
  - `-h`: displays the option
- **Output:**
  - Verification result from the MicSE

### micse_taq.sh example with cameligo

- **Input:** [raffle.mligo](../benchmarks/ligo/raffle.mligo), [raffle.storageList.mligo](../benchmarks/ligo/raffle.storageList.mligo)
- **Output:**

```bash
$ (PROJECT_DIR)/script/micse_taq.sh -C mligo -I raffle.mligo -S raffle.storageList.mligo -m syner
Initializing taqueria is done
Note: parameter file associated with "raffle.mligo" can't be found, so "raffle.parameterList.mligo" has been created for you. Use this file to define all parameter values for this contract

Compile process is done
 Final-Report :
=== Final Result ===
Time: 66.111055 sec             Memory: 0.083351 GB
Combinations: 1
#Total: 1               #Proved: 0              #Refuted: 1             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>

<< Refuted >>
> Location:(CCLOC_Pos((lin 34)(col 18))((lin 34)(col 21)))
        Category:Q_mutez_mul_nmm_no_overflow
        Refuted Path:
                - Initial Balance: 0
                - Transaction #1:
                        Amount:2
                        Parameter:
                                (|(const_or_right (Pair (Pair Int (Option String)) (Pair Int Bytes)))|
                                  (|(const_pair (Pair Int (Option String)) (Pair Int Bytes))|
                                    (|(const_pair Int (Option String))| 604801 const_option_none)
                                    (|(const_pair Int Bytes)| 1 const_bytes_nil)))
                - Transaction #2:
                        Amount:0
                        Parameter:
                                (|(const_or_left (Or Int Int))| (|(const_or_left Int)| 9223372036854775808))

<< Failed >>
```

### micse_taq.sh example with pascaligo

- **Input:** [raffle.ligo](../benchmarks/ligo/raffle.ligo), [raffle.storageList.ligo](../benchmarks/ligo/raffle.storageList.ligo)
- **Output:**

```bash
$ (PROJECT_DIR)/script/micse_taq.sh -C ligo -I raffle.ligo -S raffle.storageList.ligo -m syner
Initializing taqueria is done
Note: parameter file associated with "raffle.ligo" can't be found, so "raffle.parameterList.ligo" has been created for you. Use this file to define all parameter values for this contract

Compile process is done
 Final-Report :
=== Final Result ===
Time: 46.699528 sec             Memory: 0.067543 GB
Combinations: 1
#Total: 1               #Proved: 0              #Refuted: 1             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>

<< Refuted >>
> Location:(CCLOC_Pos((lin 27)(col 23))((lin 27)(col 26)))
        Category:Q_mutez_mul_nmm_no_overflow
        Refuted Path:
                - Initial Balance: 0
                - Transaction #1:
                        Amount:2
                        Parameter:
                                (|(const_or_right (Pair (Pair Int Int) (Pair (Option String) Bytes)))|
                                  (|(const_pair (Pair Int Int) (Pair (Option String) Bytes))|
                                    (|(const_pair Int Int)| 1 604801)
                                    (|(const_pair (Option String) Bytes)| const_option_none const_bytes_nil)))
                - Transaction #2:
                        Amount:0
                        Parameter:
                                (|(const_or_left (Or Int Int))| (|(const_or_left Int)| 9223372036854775808))

<< Failed >>
```

### micse_taq.sh example with SmartPy

- **Input:** [raffle.py](../benchmarks/smartpy/raffle.py)
- **Output:**

```bash
$ (PROJECT_DIR)/script/micse_taq.sh -C smartpy -I raffle.py -m syner
Initializing taqueria is done
Compile process is done
 Final-Report :
=== Final Result ===
Time: 73.403712 sec             Memory: 0.089329 GB
Combinations: 1
#Total: 2               #Proved: 1              #Refuted: 1             #Failed: 0
#Err: 0 #UU: 0  #UF: 0  #FU: 0  #FF: 0
<< Proved >>
> Location:(CCLOC_Pos((lin 104)(col 9))((lin 104)(col 12)))
        Category:Q_mutez_mul_nmm_no_overflow

<< Refuted >>
> Location:(CCLOC_Pos((lin 37)(col 9))((lin 37)(col 12)))
        Category:Q_mutez_mul_nmm_no_overflow
        Refuted Path:
                - Initial Balance: 0
                - Transaction #1:
                        Amount:4
                        Parameter:
                                (|(const_or_right (Or Int (Pair (Pair Int String) (Pair Int Bytes))))|
                                  (|(const_or_right (Pair (Pair Int String) (Pair Int Bytes)))|
                                    (|(const_pair (Pair Int String) (Pair Int Bytes))|
                                      (|(const_pair Int String)| 604801 "The raffle is not yet opened.")
                                      (|(const_pair Int Bytes)| 3 const_bytes_nil))))
                - Transaction #2:
                        Amount:0
                        Parameter:
                                (|(const_or_left Int)| 9223372036854775808)

<< Failed >>
```
