
type storage = int
type parameter = Setv of int | Increase

type return = operation list * storage

let setv (param, strg) = 
  if param < 100 then ([], param)
  else ([], strg)

let rec loop (x : int) : int = 
  if (x < 50) then loop (x + 1) else x
let increase (strg) = 
  let strg = strg - 1 in
  let strg = loop strg in
  (* CHECK strg <= 50 *)
  ([], strg)

let main (action, store : parameter * storage) : return = 
  (
      match action with
        Setv (n) -> setv (n, store)
      | Increase -> increase (store)
  )

