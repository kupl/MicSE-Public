FROM ocaml/opam:ubuntu-20.04-ocaml-4.10

RUN sudo apt-get update \
    && sudo apt-get install -y bc sudo \
    && sudo apt-get clean

COPY bootstrap.sh /home/opam/
RUN /bin/bash -c /home/opam/bootstrap.sh

CMD [ "micse" ]
