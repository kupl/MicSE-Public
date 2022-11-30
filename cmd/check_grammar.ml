exception Error of string

open Lib

let _ =
   try
     let _ = ExecFlow.upto_sym_exec None in
     let _ = Utils.Log.app (fun m -> m "O") in
     ()
   with
   | _ -> Utils.Log.app (fun m -> m "X")
