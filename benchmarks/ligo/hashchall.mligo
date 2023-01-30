type chall = {
    reward      : tez;
    salted_hash : bytes;
}

type chall_set = (address, chall) big_map

type storage = {
    total_reward : tez;
    commits      : chall_set;
}

type reveal = {
    chall_owner : address;
    hashable    : bytes;
    message     : unit -> operation list;
}

type parameter =
| Commit of chall
| Reveal of reveal

type return = operation list * storage

(* We use hash-commit so that a baker can not steal *)
(* commit, reveal 두가지 parameter가 존재한다. *)
let commit (p, s : chall * storage) : return =
    let commit : chall =
        {reward = p.reward; salted_hash = p.salted_hash} in (* commit을 만든다. 현재 시간과 parameter bytes를 토대로 *)
    let updated_map: chall_set =
        Big_map.update (Tezos.get_sender ()) (Some commit) s.commits in
    let s = {s with commits = updated_map}
    in ([] : operation list), s

let reveal (p, s : reveal * storage) : return =
    let commit : chall =
    match Big_map.find_opt p.chall_owner s.commits with
    | Some c -> c
    | None ->
    (failwith "You have not made a commitment to hash against yet."
        : chall)
    in
    let salted =
        Crypto.sha256 (Bytes.concat p.hashable (Bytes.pack p.chall_owner)) in
    if salted <> commit.salted_hash
    then
        (failwith "This reveal does not match your commitment.": return)
    else
        let s : storage = {s with total_reward = s.total_reward + commit.reward}
        in p.message (), s

let main (p, s : parameter * storage) : return =
    match p with
    | Commit c -> commit (c,s)
    | Reveal r -> reveal (r,s)
