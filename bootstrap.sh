#!/bin/bash

##### bootstrap.sh - set-up system and build MicSE project.
export DEBIAN_FRONTEND=noninteractive

# Env
OPAM_SWITCH_VERSION=4.10.0
Z3_VERSION=4.8.12
CORES=4

# Setup System Dependencies
echo "[NOTE] Start Setup System Dependencies"
sudo apt-get update >/dev/null
curl -s https://deb.nodesource.com/setup_16.x | sudo bash # for tacqueria installation
for pkg in "cmake" "build-essential" "python2.7" "libgmp-dev" "opam" "ocaml-findlib" "nodejs"; do
  echo "[NOTE] $pkg: Install"
  sudo apt-get install -y -qq $pkg >/dev/null 2>&1
  # if [ $(dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep -c "ok installed" 2>/dev/null) -eq 0 ]; then
  #   echo "[NOTE] $pkg: Installation started."
  #   sudo apt-get install -y -qq $pkg >/dev/null 2>&1
  #   echo "[NOTE] $pkg: Installed successfully."
  # else
  #   echo "[NOTE] $pkg: Already installed."
  # fi
done
echo "[NOTE] End-up Setup System Dependencies"

# Download MicSE
#cd ~/
#git clone https://github.com/kupl/MicSE.git
#cd MicSE

# Initialize opam
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
#echo "[NOTE] Current OCAML version is $(ocaml --version | grep -P "\d+\.\d+\.\d+" -o)"
eval $(opam env) && \
	#opam install -y -q -j $CORES dune.2.4.0 batteries.3.3.0 core.v0.14.1 menhir.20210419 ocamlgraph.2.0.0 ptime.0.8.5 yojson.1.7.0 zarith.1.11 ounit2.2.2.4 bignum.v0.14.0 ppx_deriving.5.2.1 mtime.1.2.0 logs.0.7.0 z3.4.8.11 odoc.1.5.3
  opam install -y -q -j $CORES /vagrant --deps-only
echo "[NOTE] Current OCAML version is $(ocaml --version | grep -P "\d+\.\d+\.\d+" -o)"
OPAM_LIB_DIR=~/.opam/$OPAM_SWITCH_VERSION/lib/
echo "[NOTE] End-up Initialize OPAM"

# Install Z3
# if [[ ! -d "${OPAM_LIB_DIR%%/}/z3" ]]; then
#   echo "[NOTE] Start Install Z3"
#   curl -L -o z3-$Z3_VERSION.tar.gz https://github.com/Z3Prover/z3/archive/z3-$Z3_VERSION.tar.gz >/dev/null 2>&1 && \
#     tar -zxvf z3-$Z3_VERSION.tar.gz >/dev/null 2>&1 && \
#     rm z3-$Z3_VERSION.tar.gz >/dev/null
#   Z3_DIR=~/z3-z3-$Z3_VERSION/
#   cd ${Z3_DIR%%/}/ && \
#     python2.7 scripts/mk_make.py --ml --staticlib >/dev/null
#   eval $(opam env) && \
#     make -C build -j $CORES >/dev/null 2>&1
#   eval $(opam env) && \
#     ocamlfind install z3 build/api/ml/* build/libz3-static.a >/dev/null && \
#     sudo cp build/z3 /usr/bin/z3 && \
#     rm -rf ${Z3_DIR%%/}
#   echo "[NOTE] End-up Install Z3"
# fi

# Build
if [[ ! -d "~/MicSE" ]]; then
  eval $(opam env) && cd /vagrant && make
  ln -s /vagrant ~/MicSE
  PATH=$PATH:/vagrant/bin
  echo "PATH=\$PATH:/vagrant/bin" >> /home/vagrant/.bashrc
  echo "[NOTE] End-up Install MicSE"
fi

echo "eval \$(opam env)" >> ~/.bashrc

cd ~
# Install docker for tacqueria
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install -y docker-ce
sudo usermod -aG docker ${USER}
echo "[NOTE] End-up installing docker"

# Install smartpy
echo "y" | bash <(curl -s https://smartpy.io/cli/install.sh)
PATH=$PATH:/home/vagrant/smartpy-cli
echo "PATH=\$PATH:/home/vagrant/smartpy-cli" >> /home/vagrant/.bashrc
ln -s /home/vagrant/smartpy-cli/SmartPy.sh /home/vagrant/smartpy-cli/smartpy

# Install tacqueria
# ./install_ligo_smartpy.sh
curl -LO https://taqueria.io/get/linux/taq
chmod +x taq
sudo mv taq /usr/local/bin

# install pip and tabulate for benchmarking
sudo apt-get install python3-pip
python3 -m pip install tabulate
echo "[NOTE] End-up bootstraping"
