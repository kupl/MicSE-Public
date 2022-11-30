exception Error of string

open Lib_s

let _ =
   try
    let _ = Utils.Log.app (fun m -> m "MicSE enhanced prover Start") in
     let (cfg, res) = ExecFlow_s.prover_enhanced_run None in
     let _ =
        Utils.Log.app (fun m ->
            m "Final-Report : %s" (Lib.Res.string_of_res cfg res)
        )
     in
     ()
   with
   | exc when Utils.Log.is_logger_created () ->
     Utils.Log.err (fun m ->
         m "%s\n%s" (exc |> Printexc.to_string) (Printexc.get_backtrace ())
     )
   | exc -> raise exc
