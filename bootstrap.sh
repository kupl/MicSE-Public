#!/bin/bash

##### bootstrap.sh - set-up system and build MicSE project.
export DEBIAN_FRONTEND=noninteractive

# Env
OPAM_SWITCH_VERSION=4.10.0
MICSE_PUBLIC_REPO_URL=https://github.com/kupl/MicSE-Public.git
HOME_DIR=$(eval echo ~$USER)
MICSE_DIR=$HOME_DIR/MicSE-Public
CORES=$(grep -c ^processor /proc/cpuinfo)
HALF_CORES=$(echo "${CORES}/2" | bc)
USABLE_CORES=$((HALF_CORES > 1 ? HALF_CORES : 1))

# Setup System Dependencies
echo "[NOTE] Start Setup System Dependencies"
sudo apt-get update >/dev/null
PKG_LIST=("cmake" "build-essential" "python2.7" "libgmp-dev" "opam" "ocaml-findlib" "python3" "curl" "python3-distutils" "python3-apt")
for pkg in ${PKG_LIST[@]}; do
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $pkg 2>/dev/null | grep "install ok installed")
  if [ "" = "$PKG_OK" ]; then
    echo "[NOTE] $pkg: Installation started."
    sudo apt-get install -y -qq $pkg >/dev/null 2>&1
    echo "[NOTE] $pkg: installation done."
  else
    echo "[NOTE] $pkg: Already installed."
  fi
done
echo "[NOTE] End-up Setup System Dependencies"

# Download MicSE
echo "[NOTE] Start Clone MicSE Repository"
if [ -d "$MICSE_DIR" ]; then
  echo "[NOTE] $MICSE_DIR directory is already exist."
  if [ -d "$MICSE_DIR/.git" ]; then
    git pull >/dev/null
  else
    echo "[ERROR] $MICSE_DIR: Invalid direcotry state."
    exit -1
  fi
else
  cd $HOME_DIR
  git clone $MICSE_PUBLIC_REPO_URL >/dev/null
fi
echo "[NOTE] End-up Clone MicSE Repository"

# Initialize OPAM
echo "[NOTE] Start Initialize OPAM with Installing OCAML Dependencies"
opam init -y --bare >/dev/null
opam update >/dev/null
eval $(opam env)
if [[ ! "$(ocaml --version)" =~ "$OPAM_SWITCH_VERSION" ]]; then
  if [[ "$(opam switch list 2>/dev/null | grep -c "$OPAM_SWITCH_VERSION")" -eq 0 ]]; then
    opam switch create $OPAM_SWITCH_VERSION >/dev/null
  else
    opam switch $OPAM_SWITCH_VERSION >/dev/null
  fi
fi
echo "[NOTE] Current OCAML version is $(ocaml --version | grep -P "\d+\.\d+\.\d+" -o)"
eval $(opam env) && opam install -y -q -j $USABLE_CORES $MICSE_DIR --deps-only
echo "eval \$(opam env)" >> $HOME_DIR/.profile
echo "[NOTE] End-up Initialize OPAM"

# Build MicSE
MICSE_BIN_DIR=$MICSE_DIR/bin
if [[ ! -d "$MICSE_BIN_DIR" ]]; then
  echo "[NOTE] Start Install MicSE"
  eval $(opam env) && cd $MICSE_DIR && make
  echo "PATH=\$PATH:$MICSE_BIN_DIR" >> $HOME_DIR/.profile
  echo "[NOTE] End-up Install MicSE"
fi

# Install nodejs v16 for taqueria
curl -s https://deb.nodesource.com/setup_16.x | sudo bash
sudo apt install nodejs -y

# Install docker for taqueria
echo "[NOTE] Start installing docker for tacqueria"
curl -s https://deb.nodesource.com/setup_16.x | sudo bash # for tacqueria installation
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}
sudo chmod 757 /var/run/docker.sock
echo "[NOTE] End-up installing docker for tacqueria"

# Install tacqueria
curl -LO https://taqueria.io/get/linux/taq
chmod +x taq
sudo mv taq /usr/local/bin
mkdir $HOME_DIR/.taq-settings
echo -e "{\n    \"consent\": \"opt_out\"\n}" > $HOME_DIR/.taq-settings/taq-settings.json

# install pip and tabulate for benchmarking
sudo apt-get install -y python3-pip
python3 -m pip install tabulate pandas

exec $SHELL
echo "[NOTE] End-up bootstraping"
