type storage = tez

type parameter =
  Increment of tez
| Decrement of tez
| Reset

type return = operation list * storage

// Two entrypoints

let add (store : storage) (delta : tez) : storage = store + delta
let sub (store : storage) (delta : tez) : storage = 
  let store_n : nat = store / 1mutez in
  let delta_n : nat = delta / 1mutez in
  let result_i : int = store_n - delta_n in
  let result_n : nat = abs(result_i) in
  1mutez * result_n

(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)
   
let main (action, store : parameter * storage) : return =
 ([] : operation list),    // No operations
 (match action with
   Increment (n) -> add store n
 | Decrement (n) -> sub store n
 | Reset         -> 0mutez)