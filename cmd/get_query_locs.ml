exception Error of string

open Lib
open! Core

let _ =
   let open Res in
   let ( (_, _, (_ : Tz.mich_i Tz.cc)),
         (_ : Tz.mich_v Tz.cc option),
         (se_result : Se.se_result),
         (_ : Tz.sym_state)
       ) =
      ExecFlow.upto_sym_exec None
   in
   let qidset : QIDSet.t =
      Se.SSet.fold se_result.sr_queries ~init:QIDSet.empty ~f:(fun aset ss ->
          let rmci = TzUtil.get_reduced_mci ss.ss_block_mci in
          QIDSet.add aset
            {
              qid_loc = rmci.rmci_loc;
              qid_cat =
                (match rmci.rmci_cutcat with
                | RMCC_query q -> q
                | _            -> failwith __LOC__);
            }
      )
   in
   QIDSet.iter qidset ~f:(fun qid ->
       let (l, c) =
          match qid.qid_loc with
          | Tz.CCLOC_Unknown     -> (-1, -1)
          | Tz.CCLOC_Pos (p1, _) -> (p1.lin, p1.col)
          (* | Tz.CCLOC_Pos (_, p2) -> (p2.lin, p2.col) *)
       in
       Utils.Log.app (fun m -> m "%d %d" l c)
   )
