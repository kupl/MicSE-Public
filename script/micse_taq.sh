#!/bin/bash

Help()
{
    echo "Syntax: ./micse_taq.sh [-I|S|M|T|Z|C]"
    echo "options:"
    echo "I     The file path of input Michelson code. (REQUIRED)"
    echo "S     The file path of initial storage information that the target contract has. (REQUIRED)"
    echo "M     The memory budget for overall MicSE process in GB. (default: 5GB)"
    echo "T     The time budget for overall MicSE process in seconds. (default: 360sec)"
    echo "C     The file is Ligo or SmartPy"
    echo "m     Mode of MicSE (default: syner -> micse)"
    echo "h     displays the option"
    echo ""
}

INPUTFILE=""
STORAGEFILE=""
MEMBUDGET=5
TIMEBUDGET=3600
CODE=""
MODE="syner"

while getopts ":I:S:M:T:Z:C:Z:m:h" option;
do
    case "$option" in
        I) INPUTFILE=$OPTARG;;#echo "Found the -I option";
            #echo "Found the -I option, with from $INPUTFILE";;
        S) STORAGEFILE=$OPTARG;;#echo "Found the -S option";
            #echo "Found the -S option, with from $STORAGEFILE";;
        M) echo "Found the -M option";MEMBUDGET=$OPTARG;
            echo "Found the -M option, memory budget : $MEMBUDGET";;
        T) echo "Found the -T option";TIMEBUDGET=$OPTARG;
            echo "Found the -T option, Time Budget : $TIMEBUDGET";;
        C) CODE="${OPTARG,,}";;#echo "Found the -C option";
            #echo "Found the -C option, Code format : $CODE";;
        m) MODE="${OPTARG,,}";;#echo "Found the -m option";MODE="${OPTARG,,}";
            #echo "Found the -m option, Code format : $MODE";;
        h) echo "Found help option";
            Help
            exit;;
        #--) shift
        #   break;;
        \?) echo "$1 is not an option";
            Help
            exit;;
    esac
done


### check whether CODE file format is empty or it's value is not (ligo or smartpy)
if [ "$CODE" == "" ] || [ "$CODE" != "mligo" -a "$CODE" != "ligo" -a "$CODE" != "religo" -a "$CODE" != "jsligo"  -a "$CODE" != "smartpy" ];then
    echo "Code format is wrong"
    echo "micse_taq ..... -C [mligo|ligo|religo|jsligo|SmartPy] <- (case in-sensitive)"
    exit 1
fi

### check whether input file is exists or empty string
if [ "$CODE" != "smartpy"  ];then
    ## if mligo, we need two files which are input .tz file and .storageList.mligo file
    if [ "$INPUTFILE" == "" -o ! -e "$INPUTFILE" -o "$STORAGEFILE" == "" -o ! -e "$STORAGEFILE" ];then
        echo "Input .${CODE} file is something wrong"
        Help
        exit 1
    else
        ### change input files's name to absolute path
        INPUTFILE=`readlink -f $INPUTFILE`
        STORAGEFILE=`readlink -f $STORAGEFILE`
    fi
elif [ "$CODE" == "smartpy" ];then
    ## if smartpy, storage file is not needed
    if [ "$INPUTFILE" == "" -o ! -e "$INPUTFILE" ];then
        echo "Input .py file is something wrong"
        Help
        exit 1
    else
        ### change input files's name to absolute path and delete storage file variable
        INPUTFILE=`readlink -f $INPUTFILE`
        unset STORAGEFILE
    fi
fi



#### make taq compile 환경

TEMPDIR=$(mktemp -d ./tmp.XXXXXX)

if [ ! -d $TEMPDIR ]; then
    echo "mktemp command is failed"
    exit 1
fi

## enter to working-dir
cd $TEMPDIR

## initialize taqueria
taq init ./ >/dev/null
echo "Initializing taqueria is done"
## prepare compiling
if [ $CODE != "smartpy" ]; then
    taq install @taqueria/plugin-ligo >/dev/null
    cp $INPUTFILE $STORAGEFILE ./contracts/
    BASENAME=`basename $INPUTFILE .$CODE`
    taq compile "$BASENAME.$CODE" >/dev/null
    TARGET="./artifacts/$BASENAME.tz"
    TARGET_STORAGE="./artifacts/$BASENAME.default_storage.tz"
elif [ $CODE == "smartpy" ]; then
    taq install @taqueria/plugin-smartpy >/dev/null
    cp $INPUTFILE ./contracts/
    BASENAME=`basename $INPUTFILE .py`
    taq compile "$BASENAME.py" >/dev/null
    DIRNAME=$(cat ./contracts/"$BASENAME.py" | grep "sp.add_compilation_target(" | cut -d '"' -f2)
    TARGET="./artifacts/$BASENAME.tz"
    TARGET_STORAGE="./artifacts/$BASENAME.default_storage.tz"
fi

echo "Compile process is done"

if [ ! -f "$TARGET" -o ! -f "$TARGET_STORAGE" ]; then
    echo "Compile process went wrong"
    cd ../
    rm -r $TEMPDIR
    exit 1
fi

### Compiled well and last verify michelson file

if [ $MODE == "nonco" ]; then
    baseline -I $TARGET -S $TARGET_STORAGE -T $TIMEBUDGET -M $MEMBUDGET
elif [ $MODE == "syner" ]; then
    micse    -I $TARGET -S $TARGET_STORAGE -T $TIMEBUDGET -M $MEMBUDGET
fi

##### clean up work directory
cd ../
rm -r $TEMPDIR
