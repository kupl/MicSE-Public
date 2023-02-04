(* Manage_s : Manager for MicSE-Synergetic *)

exception ManageSError of string

open! Core


(******************************************************************************)
(******************************************************************************)
(* Common Datatypes                                                           *)
(******************************************************************************)
(******************************************************************************)

(* Set of Tz.mich_f *)
module MFSet = Set.Make (Tz.MichF_cmp)

(******************************************************************************)
(******************************************************************************)
(* Status Printing                                                            *)
(******************************************************************************)
(******************************************************************************)

let print_num_of_cands : Res.config -> Res.res -> unit =
   let open Res in
   let module RMCIMap = Map.Make (Tz.RMichCutInfo_cmp) in
   let module PPSet = Set.Make (Res.PPath) in
   let (print_at : int ref) = ref 0 in
   fun _ { r_qr_lst; r_cands; _ } ->
   if Option.is_none !Utils.Argument.status_interval
   then ()
   else if !print_at > 0
   then decr print_at
   else (
     let _ =
        Utils.Log.debug (fun m ->
            m "> Intermediate Status [Number of Candidates]\n%s\n"
              (List.map r_qr_lst
                 ~f:(fun { qr_qid; qr_prv_flag; qr_rft_flag; _ } ->
                   if (not (Prove.check_number_of_cands qr_qid r_cands))
                      || equal_refuter_flag qr_rft_flag RF_r
                      || not (equal_prover_flag qr_prv_flag PF_u)
                   then ""
                   else
                     Printf.sprintf "QID: %s\n\t%s"
                       (qr_qid |> Tz.sexp_of_qid |> SexpUtil.to_string)
                       (List.map (Inv.RMCIMap.keys r_cands) ~f:(fun rmci ->
                            let (cands : Inv.cand list) =
                               Inv.find_ordered_cand_by_rmci r_cands rmci qr_qid
                                 ~remove_unflaged:true ~remove_not_precond:true
                            in
                            (rmci
                            |> Tz.sexp_of_r_mich_cut_info
                            |> SexpUtil.to_string
                            )
                            ^ ": "
                            ^ string_of_int (List.length cands)
                        )
                       |> String.concat ~sep:"\n\t"
                       )
               )
              |> List.filter ~f:(fun s -> not (String.is_empty s))
              |> String.concat ~sep:"\n"
              )
        )
     in
     let _ = print_at := Option.value_exn !Utils.Argument.status_interval in
     ()
   )
(* function print_num_of_cands end *)

let print_size_of_cand_space : Res.res -> unit =
   let open Res in
   let module RMCIMap = Map.Make (Tz.RMichCutInfo_cmp) in
   let module QIDMap = Map.Make (Tz.QId_cmp) in
   let module CMap = Map.Make (Inv.Cand_cmp) in
   let module PPSet = Set.Make (Res.PPath) in
   fun { r_cands; _ } ->
   let (init_size : int RMCIMap.t) =
      RMCIMap.map r_cands ~f:(fun cmap ->
          CMap.count cmap ~f:(fun (_, _) -> true) + 1
      )
   in
   let (done_size : int RMCIMap.t) =
      RMCIMap.map r_cands ~f:(fun cmap ->
          CMap.count cmap ~f:(fun (flag, _) -> flag) + 1
      )
   in
   let (init_overall : int) =
      RMCIMap.fold init_size ~init:1 ~f:(fun ~key:_ ~data acc -> acc * data)
   in
   let (done_overall : int) =
      RMCIMap.fold done_size ~init:1 ~f:(fun ~key:_ ~data acc -> acc * data)
   in
   let _ =
      Utils.Log.debug (fun m ->
          m
            "Cand Status\n> Size of Candidate Space at Initial State: %d\n\t%s\n> Size of Candidate Space at Final State: %d\n\t%s\n> Decrement: %.1f\n"
            init_overall
            (List.map (RMCIMap.to_alist init_size) ~f:(fun (rmci, numb) ->
                 Printf.sprintf "%s: %d"
                   (rmci |> Tz.sexp_of_r_mich_cut_info |> SexpUtil.to_string)
                   numb
             )
            |> String.concat ~sep:"\n\t"
            )
            done_overall
            (List.map (RMCIMap.to_alist done_size) ~f:(fun (rmci, numb) ->
                 Printf.sprintf "%s: %d"
                   (rmci |> Tz.sexp_of_r_mich_cut_info |> SexpUtil.to_string)
                   numb
             )
            |> String.concat ~sep:"\n\t"
            )
            ((float_of_int (init_overall - done_overall)
              /. float_of_int init_overall
              *. 1000.
             |> Float.round_down
             )
            /. 10.
            )
      )
   in
   ()
(* function print_num_of_cands end *)

let print_picked_paths : Res.res -> unit =
   let open Res in
   let (print_at : int ref) = ref 0 in
   fun res ->
   if Option.is_none !Utils.Argument.status_interval
   then ()
   else if !print_at > 0
   then decr print_at
   else (
     let _ = Utils.Log.debug (fun m -> m "> List of Picked Paths") in
     let _ =
        let s =
           List.fold res.r_qr_lst ~init:"" ~f:(fun accstr qres ->
               let query_id_str =
                  accstr
                  ^ "\n    Query-Id : "
                  ^ (Tz.sexp_of_qid qres.qr_qid |> Sexp.to_string)
               in
               PPSet.fold qres.qr_last_picked_paths ~init:query_id_str
                 ~f:(fun acc pp ->
                   acc
                   ^ "\n    Score : "
                   ^ (pp.pp_score
                     |> List.sexp_of_t sexp_of_int
                     |> Sexp.to_string
                     )
                   ^ "\tPathSummary : "
                   ^ (MState.get_summary pp.pp_mstate
                     |> MState.sexp_of_summary
                     |> Sexp.to_string
                     )
               )
           )
        in
        let _ = Utils.Log.debug (fun m -> m "%s" s) in
        ()
     in
     let _ = print_at := Option.value_exn !Utils.Argument.status_interval in
     ()
   )

let print_expanded_paths : Res.res -> unit =
   let open Res in
   let (print_at : int ref) = ref 0 in
   fun res ->
   if Option.is_none !Utils.Argument.status_interval
   then ()
   else if !print_at > 0
   then decr print_at
   else (
     let _ = Utils.Log.debug (fun m -> m "> List of Expanded Paths") in
     let _ =
        let s =
           List.fold res.r_qr_lst ~init:"" ~f:(fun accstr qres ->
               let query_id_str =
                  accstr
                  ^ "\n    Query-Id : "
                  ^ (Tz.sexp_of_qid qres.qr_qid |> Sexp.to_string)
               in
               PPSet.fold qres.qr_exp_ppaths ~init:query_id_str
                 ~f:(fun acc pp ->
                   acc
                   ^ "\n    Score : "
                   ^ (pp.pp_score
                     |> List.sexp_of_t sexp_of_int
                     |> Sexp.to_string
                     )
                   ^ "\tPathSummary : "
                   ^ (MState.get_summary pp.pp_mstate
                     |> MState.sexp_of_summary
                     |> Sexp.to_string
                     )
               )
           )
        in
        let _ = Utils.Log.debug (fun m -> m "%s" s) in
        ()
     in
     let _ = print_at := Option.value_exn !Utils.Argument.status_interval in
     ()
   )

(******************************************************************************)
(******************************************************************************)
(* Entry Point                                                                *)
(******************************************************************************)
(******************************************************************************)

let enhanced_prover_run : Res.config -> Res.res -> Res.res =
   let log_report : Res.config -> Res.res -> unit =
     fun cfg res ->
     Utils.Log.info (fun m -> m "> Report: %s" (Res.string_of_res_rough cfg res))
     (* inner-function log_report end *)
   in
   let rec enhanced_prover_run_i : Res.config -> Res.res -> Res.res =
      let open Res in
      fun cfg res ->
      if Prove.naive_run_escape_condition cfg res
      then res
      else (
        let _ = log_report cfg res in
        let _ = Utils.Log.info (fun m -> m "> Path Picking Turn Start") in
        let (pp_res : res) =
           let (r_qr_lst : qres list) =
              List.map res.r_qr_lst ~f:(fun qres ->
                  let ( (qr_last_picked_paths : PPSet.t),
                        (unpicked_paths : PPSet.t)
                      ) =
                     Coop.pick_refutable_path_f_gen cfg res qres.qr_qid
                       (cfg.cfg_smt_ctxt, cfg.cfg_smt_slvr)
                       qres.qr_exp_ppaths
                  in
                  let (expanded_paths : PPSet.t) =
                     PPSet.fold qr_last_picked_paths ~init:PPSet.empty
                       ~f:(fun acc pp ->
                         PPSet.union
                           (Refute.expand_pp ~m_view:cfg.cfg_m_view pp)
                           acc
                     )
                  in
                  let (qr_exp_ppaths : PPSet.t) =
                     PPSet.union expanded_paths unpicked_paths
                  in
                  { qres with qr_exp_ppaths; qr_last_picked_paths }
              )
           in
           { res with r_qr_lst }
        in
        let _ = Utils.Log.info (fun m -> m "> Path Picking Turn End") in
        let _ =
           Utils.Log.info (fun m -> m "> Precondition Search Turn Start")
        in
        let (ps_res : Res.res) =
           if Coop.syn_run_escape_condition cfg pp_res
           then pp_res
           else Coop.syn_run_res_atomic_action cfg pp_res
        in
        let _ = Utils.Log.info (fun m -> m "> Precondition Search Turn End") in
        let _ = print_num_of_cands cfg ps_res in
        let _ = Utils.Log.info (fun m -> m "> Prover Turn Start") in
        let (p_res : Res.res) =
           if Prove.naive_run_escape_condition cfg ps_res
           then ps_res
           else Prove.naive_run_res_atomic_action cfg ps_res
        in
        let _ = Utils.Log.info (fun m -> m "> Prover Turn End") in
        enhanced_prover_run_i cfg p_res
      )
      (* inner-function enhanced_prover_run_i end *)
   in
   fun cfg res ->
   let _ = log_report cfg res in
   let _ = Utils.Log.info (fun m -> m "> Prover Turn Start") in
   let (p_res : Res.res) = Manage.initial_prove_run_res_atomic_action cfg res in
   let _ = Utils.Log.info (fun m -> m "> Prover Turn End") in
   let (e_res : Res.res) = enhanced_prover_run_i cfg p_res in
   let _ = log_report cfg e_res in
   e_res
(* function syn_run end *)

let syn_run_escape_condition : Res.config -> Res.res -> bool =
   let open Res in
   fun { cfg_timer; cfg_memory; _ } { r_qr_lst; _ } ->
   if (* 1. Timeout *)
      Utils.Time.is_timeout cfg_timer
   then (
     Utils.Log.debug (fun m -> m "syn_run_escape_condition : TIMEOUT!!!");
     true
   )
   else if (* 2. Memoryout *)
           Utils.Memory.is_memoryout cfg_memory
   then (
     Utils.Log.debug (fun m -> m "syn_run_escape_condition : MEMORYOUT!!!");
     true
   )
   else if (* 2. Every queries are PF_p or PF_f or RF_r or RF_f *)
           List.for_all r_qr_lst ~f:(fun { qr_prv_flag; qr_rft_flag; _ } ->
               equal_prover_flag qr_prv_flag PF_p
               || equal_refuter_flag qr_rft_flag RF_r
               || equal_prover_flag qr_prv_flag PF_f
                  && equal_refuter_flag qr_rft_flag RF_f
           )
   then (
     Utils.Log.debug (fun m -> m "syn_run_escape_condition : ALL NON-UNKNOWN!!!");
     true
   )
   else false
(* function syn_run_escape_condition end *)

let syn_run : Res.config -> Res.res -> Res.res =
   let log_report : Res.config -> Res.res -> unit =
     fun cfg res ->
     Utils.Log.info (fun m -> m "> Report: %s" (Res.string_of_res_rough cfg res))
     (* inner-function log_report end *)
   in
   let rec syn_run_i : Res.config -> Res.res -> Res.res =
     fun cfg res ->
     if syn_run_escape_condition cfg res
     then res
     else (
       let _ = log_report cfg res in
       let _ = Utils.Log.info (fun m -> m "> Refuter Turn Start") in
       let (r_res : Res.res) =
          (* TODO : modify naive run escape condition func to guided-run escape condition check function *)
          if Refute.naive_run_escape_condition cfg res
          then res
          else
            Refute.trxpath_score_saved_guided_run_res_atomic_action
              ~pick_f_gen:Refuter_score.gen_common_prec_elim_floatscore
              ~score_f_gen:Refuter_score.gen_common_prec_elim_scorepolicy cfg
              res
       in
       let _ = Utils.Log.info (fun m -> m "> Refuter Turn End") in
       let _ = print_picked_paths r_res in
       (* let _ = print_expanded_paths r_res in *)
       let _ = log_report cfg r_res in
       let _ = Utils.Log.info (fun m -> m "> Precondition Search Turn Start") in
       let (ps_res : Res.res) =
          if Coop.syn_run_escape_condition cfg r_res
          then res
          else Coop.syn_run_res_atomic_action cfg r_res
       in
       let _ = Utils.Log.info (fun m -> m "> Precondition Search Turn End") in
       let _ = print_num_of_cands cfg ps_res in
       let _ = log_report cfg ps_res in
       let _ = Utils.Log.info (fun m -> m "> Prover Turn Start") in
       let (p_res : Res.res) =
          if Prove.naive_run_escape_condition cfg ps_res
          then ps_res
          else Prove.naive_run_res_atomic_action cfg ps_res
       in
       let _ = Utils.Log.info (fun m -> m "> Prover Turn End") in
       syn_run_i cfg p_res
     )
   in
   (* inner-function syn_run_i end *)
   fun cfg res ->
   let _ = log_report cfg res in
   let _ = Utils.Log.info (fun m -> m "> Refuter Turn Start") in
   let (r_res : Res.res) =
      Manage.initial_refute_run_res_atomic_action cfg res
   in
   let _ = Utils.Log.info (fun m -> m "> Refuter Turn End") in
   let _ = log_report cfg r_res in
   let _ = Utils.Log.info (fun m -> m "> Prover Turn Start") in
   let (p_res : Res.res) =
      Manage.initial_prove_run_res_atomic_action cfg r_res
   in
   let _ = Utils.Log.info (fun m -> m "> Prover Turn End") in
   let (s_res : Res.res) = syn_run_i cfg p_res in
   let _ = log_report cfg s_res in
   s_res
(* function syn_run end *)
