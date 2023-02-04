(* ExecFlow provides synergetic main execution flow functions for testing. *)

open! Core

(******************************************************************************)
(******************************************************************************)
(* Execution Flow Components                                                  *)
(******************************************************************************)
(******************************************************************************)

let coop_prover_refuter_toss : string array option -> Res.config * Res.res =
   let open Res in
   fun argv_opt ->
   let ( (_, _, (tz_code : Tz.mich_i Tz.cc)),
         (init_strg_opt : Tz.mich_v Tz.cc option),
         (se_result : Se.se_result),
         (init_state : Tz.sym_state)
       ) =
      ExecFlow.upto_sym_exec argv_opt
   in
   let (cfg : Res.config) =
      Res.init_config tz_code init_strg_opt se_result init_state
   in
   let (init_res : Res.res) = Res.init_res cfg in
   let (init_res : Res.res) =
      (* Replace existing query-paths to trx-paths *)
      let open Res.PPath in
      let _ =
         (* EXPERIMENT MODE *)
         if not !Res.exp_prover_no_benefit_mode
         then ()
         else
           List.iter init_res.r_qr_lst ~f:(fun { qr_qid; _ } ->
            Res.exp_prover_path_pool :=
                 QIDMap.update !Res.exp_prover_path_pool qr_qid ~f:(fun _ ->
                     QIDMap.find_exn cfg.cfg_query_paths qr_qid
                     |> List.map ~f:(fun ms ->
                            {
                              pp_mstate = ms;
                              pp_score = [];
                              pp_satisfiability = None;
                            }
                        )
                     |> Res.PPSet.of_list
                 )
           )
         (* EXPERIMENT MODE *)
      in
      {
        init_res with
        r_qr_lst =
          List.map init_res.r_qr_lst ~f:(fun qres ->
              {
                qres with
                qr_exp_ppaths =
                  QIDMap.find_exn cfg.cfg_query_paths qres.qr_qid
                  |> List.map ~f:(fun ms ->
                         {
                           pp_mstate = ms;
                           pp_score = [];
                           pp_satisfiability = None;
                         }
                     )
                  |> Res.PPSet.of_list;
              }
          );
      }
   in
   let _ =
      (* cfg.cfg_m_view and res.r_cands debugging info *)
      let open Se in
      let module RMCIMap = Se.SSGraph.RMCIMap in
      RMCIMap.iteri cfg.cfg_m_view ~f:(fun ~key ~data:x ->
          Utils.Log.debug (fun m ->
              m
                "%s:\n\t> # of pred state: %d\n\t> # of succ state: %d\n\t> # of candidates: %d"
                (Tz.sexp_of_r_mich_cut_info key |> Core.Sexp.to_string)
                (SSet.length x.pred) (SSet.length x.succ)
                (Inv.find_cand_by_rmci init_res.r_cands key |> Map.length)
          )
      )
   in
   let (res : Res.res) = Manage_s.syn_run cfg init_res in
   (cfg, res)
(* function coop_prover_refuter_toss end *)

let prover_enhanced_run : string array option -> Res.config * Res.res =
   let open Res in
   fun argv_opt ->
   let ( (_, _, (tz_code : Tz.mich_i Tz.cc)),
         (init_strg_opt : Tz.mich_v Tz.cc option),
         (se_result : Se.se_result),
         (init_state : Tz.sym_state)
       ) =
      ExecFlow.upto_sym_exec argv_opt
   in
   let (cfg : Res.config) =
      Res.init_config tz_code init_strg_opt se_result init_state
   in
   let (init_res : Res.res) = Res.init_res cfg in
   let _ =
      (* cfg.cfg_m_view and res.r_cands debugging info *)
      let open Se in
      let module RMCIMap = Se.SSGraph.RMCIMap in
      RMCIMap.iteri cfg.cfg_m_view ~f:(fun ~key ~data:x ->
          Utils.Log.debug (fun m ->
              m
                "%s:\n\t> # of pred state: %d\n\t> # of succ state: %d\n\t> # of candidates: %d"
                (Tz.sexp_of_r_mich_cut_info key |> Core.Sexp.to_string)
                (SSet.length x.pred) (SSet.length x.succ)
                (Inv.find_cand_by_rmci init_res.r_cands key |> Map.length)
          )
      )
   in
   let (res : Res.res) = Manage_s.enhanced_prover_run cfg init_res in
   let _ = Manage_s.print_size_of_cand_space res in
   (cfg, res)
