(lang dune 2.4)

(name micse)

(version 0.0.0)

(generate_opam_files true)

(source
 (uri "git+https://github.com/kupl/MicSE-Public.git"))

(bug_reports "https://github.com/kupl/MicSE-Public/issues")

(homepage "https://github.com/kupl/MicSE-Public")

(license MIT)

(authors
  "Jisuk Byun <grayplc@korea.ac.kr>"
  "Heewoong Jang <jormal@korea.ac.kr>"
  "Hyun Do Jeong <doslahtm@korea.ac.kr>")

(maintainers
  "Jisuk Byun <grayplc@korea.ac.kr>"
  "Heewoong Jang <jormal@korea.ac.kr>"
  "Hyun Do Jeong <doslahtm@korea.ac.kr>")

(package
  (name micse)
  (synopsis "The Michelson Symbolic vErifier, for verifying and testing the integrity of smart contracts in the Tezos blockchain")
  (depends
    (dune (= 2.4.0))
    (batteries (= 3.3.0))
    (core (= v0.14.1))
    (menhir (= 20210419))
    (ocamlgraph (= 2.0.0))
    (ptime (= 0.8.5))
    (yojson (= 1.7.0))
    (zarith (= 1.11))
    (ounit2 (= 2.2.4))
    (bignum (= v0.14.0))
    (ppx_deriving (= 5.2.1))
    (mtime (= 1.2.0))
    (logs (= 0.7.0))
    (z3 (= 4.8.13))
    (odoc (= 1.5.3))
  )
)
(using menhir 2.1)
