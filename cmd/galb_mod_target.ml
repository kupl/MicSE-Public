open! Core
open Lib

(******************************************************************************)
(* CONSTANTS                                                                  *)
(******************************************************************************)

let const_COMB_N : int = 10

(* PROCESS_A makes BALANCE < (fee_acc + total_deposit) *)
let const_PROCESS_A : int list = [ 0; 9; 10; 12; 13; 14; 15; 17; 19; 20; 23 ]

(* PROCESS_B makes BALANCE < total_deposit *)
let const_PROCESS_B : int list = const_PROCESS_A @ [ 4; 8 ]

let const_TARGET_SCENARIOS : int list list = [ const_PROCESS_B ]

let const_SKIP_FIRST_N : int = 0

(******************************************************************************)
(* UTILITIES                                                                  *)
(******************************************************************************)

let debuglog s = Utils.Log.debug (fun m -> m "%s" s)

(******************************************************************************)
(* LOGICS                                                                     *)
(******************************************************************************)

let init_config_custom :
    Tz.mich_i Tz.cc ->
    Tz.mich_v Tz.cc option ->
    Se.se_result ->
    Tz.sym_state ->
    Res.config =
   let open Res in
   fun _ cfg_istrg_opt cfg_se_res cfg_istate ->
   let (cfg_istrg : Tz.mich_v Tz.cc) =
      match cfg_istrg_opt with
      | Some v -> v
      | None   -> failwith "ExecFlow : config_base : cfg_istrg = None"
   in
   let (cfg_qid_set : QIDSet.t) =
      SSet.fold cfg_se_res.sr_queries ~init:QIDSet.empty
        ~f:(fun cfg_qid_set qs ->
          QIDSet.add cfg_qid_set (TzUtil.qid_of_mci_exn qs.ss_block_mci)
      )
   in
   let (cfg_smt_ctxt : Smt.Ctx.t) = Vc.gen_ctx () in
   {
     cfg_timer =
       Utils.Time.create
         ~budget:!Utils.Argument.total_timeout
         () ~key_lst:[ "report" ];
     cfg_memory = Utils.Memory.create ~budget:!Utils.Argument.memory_bound ();
     cfg_istate;
     cfg_istrg;
     cfg_se_res;
     cfg_qid_set;
     cfg_m_view =
       Se.SSGraph.construct_mci_view ~basic_blocks:cfg_se_res.sr_blocked;
     (* cfg_trx_paths : No need in this command *)
     cfg_trx_paths = [];
     (* cfg_query_paths : No need in this command *)
     cfg_query_paths = Res.QIDMap.empty;
     cfg_imap = Igdt.RMCIMap.empty;
     cfg_smt_ctxt;
     cfg_smt_slvr = Vc.gen_solver cfg_smt_ctxt;
     cfg_ppath_k = 2;
     cfg_cand_k = 2;
     cfg_comb_k = 50;
   }
(* function init_config_custom end *)

(******************************************************************************)
(* MAIN FUNCTION                                                              *)
(******************************************************************************)

let _ =
   let _ = print_endline "ExecFlow.upto_sym_exec Start" in
   let ( (_, _, (tz_code : Tz.mich_i Tz.cc)),
         (init_strg_opt : Tz.mich_v Tz.cc option),
         (se_result : Se.se_result),
         (init_state : Tz.sym_state)
       ) =
      ExecFlow.upto_sym_exec None
   in
   let init_strg = Option.value_exn init_strg_opt in
   let _ = debuglog "ExecFlow.upto_sym_exec End" in
   let _ = debuglog "init_config_custom Start" in
   let (cfg : Res.config) =
      init_config_custom tz_code init_strg_opt se_result init_state
   in
   let _ = debuglog "init_config_custom End" in
   let _ =
      Utils.Log.debug (fun m ->
          m "[CONSTANTS] : # QueryStates = %d"
            (Se.SSet.length se_result.sr_queries)
      )
   in
   let find_block_ss : int -> Tz.sym_state =
     fun n ->
     Se.SSet.find_exn se_result.sr_blocked ~f:(fun ss ->
         Tz.equal_sym_state_id [ n ] ss.ss_id
     )
   in
   let gen_mstate : int list -> MState.t -> MState.t =
     fun nl ms ->
     List.fold_right nl ~init:ms ~f:(fun n ms ->
         MState.cons (find_block_ss n) ms
     )
   in
   let target_sat_rft : int list -> unit =
     fun nl ->
     let _ =
        let (init_lst, fold_lst) = List.split_n nl const_SKIP_FIRST_N in
        (* run istrg+path sat *)
        List.fold_left ~init:init_lst fold_lst ~f:(fun acc n ->
            let _ = debuglog ("PATH : " ^ string_of_int n) in
            let ms = gen_mstate acc (MState.init (find_block_ss n)) in
            let start_state = MState.get_first_ss ms in
            let init_strg_fmla =
               Vc.fmla_for_initial_storage ~sctx:start_state.ss_id
                 start_state.ss_start_mci start_state.ss_start_si init_strg
            in
            let vc = Vc.gen_sp_from_ms ms init_strg_fmla |> TzUtil.opt_mf in
            let (result, _) =
               match vc with
               | MF_and lst ->
                 Vc.check_sat_lst cfg.cfg_smt_ctxt cfg.cfg_smt_slvr lst
               | _          -> Vc.check_sat cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc
            in
            let _ =
               Utils.Log.debug (fun m ->
                   m "%s : %s"
                     ((MState.get_summary ms).sm_s_id
                     |> List.to_string ~f:string_of_int
                     )
                     (Smt.Solver.string_of_sat result)
               )
            in
            acc @ [ n ]
        )
     in
     let _ =
        (* 0. run 1 and 2 for every query states *)
        let refutable_mstates : Refute.MSSet.t =
           Refute.MSSet.map se_result.sr_queries ~f:(fun qs ->
               gen_mstate nl (MState.init qs)
           )
        in
        Refute.MSSet.iter refutable_mstates ~f:(fun ms ->
            let summary_str =
               Tz.sexp_of_sym_state_id (MState.get_summary ms).sm_s_id
               |> Sexp.to_string
            in
            (* 1. run istrg + path + querystate sat *)
            let start_state = MState.get_first_ss ms in
            let init_strg_fmla =
               Vc.fmla_for_initial_storage ~sctx:start_state.ss_id
                 start_state.ss_start_mci start_state.ss_start_si init_strg
            in
            let sat_vc = Vc.gen_sp_from_ms ms init_strg_fmla |> TzUtil.opt_mf in
            let (sat_result, _) =
               match sat_vc with
               | MF_and lst ->
                 Vc.check_sat_lst cfg.cfg_smt_ctxt cfg.cfg_smt_slvr lst
               | _          ->
                 Vc.check_sat cfg.cfg_smt_ctxt cfg.cfg_smt_slvr sat_vc
            in
            let _ =
               Utils.Log.debug (fun m ->
                   m "%s : %s"
                     ((MState.get_summary ms).sm_s_id
                     |> List.to_string ~f:string_of_int
                     )
                     (Smt.Solver.string_of_sat sat_result)
               )
            in
            (* 2. run full path refute *)
            match
              Refute.refute_lst cfg.cfg_smt_ctxt cfg.cfg_smt_slvr init_strg
                { pp_mstate = ms; pp_satisfiability = None; pp_score = [] }
            with
            | (Some (_, Smt.Solver.SAT), Some mdl) ->
              Utils.Log.debug (fun m ->
                  m "%s : [REFUTE-SAT]\n%s" summary_str (Smt.Model.to_string mdl)
              )
            | (Some (_, Smt.Solver.UNKNOWN), _) ->
              Utils.Log.debug (fun m -> m "%s : [REFUTE-UNK]" summary_str)
            | (Some (_, Smt.Solver.UNSAT), _) ->
              Utils.Log.debug (fun m -> m "%s : [REFUTE-UNSAT]" summary_str);
              List.iter
                (Z3.Solver.get_unsat_core (Smt.Solver.read cfg.cfg_smt_slvr))
                ~f:(fun exp -> print_endline (Z3.Expr.to_string exp))
            | (Some (_, Smt.Solver.SAT), None) ->
              Utils.Log.debug (fun m ->
                  m "%s : [REFUTE-ERR] SAT BUT NO MODEL EXISTS" summary_str
              )
            | (None, _) ->
              Utils.Log.debug (fun m ->
                  m "%s : [REFUTE-ERR] invalid Merged-State" summary_str
              )
        )
     in
     ()
   in
   List.iter const_TARGET_SCENARIOS ~f:target_sat_rft
(* function target_sat_rft end *)
