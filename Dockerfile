FROM ocaml/opam:ubuntu-20.04-ocaml-4.10

RUN sudo apt-get update \
    && sudo apt-get install -y bc sudo wget \
    && sudo apt-get clean

RUN wget -O - https://raw.githubusercontent.com/kupl/MicSE-Public/main/bootstrap.sh | /bin/bash

WORKDIR /home/opam/MicSE-Public
