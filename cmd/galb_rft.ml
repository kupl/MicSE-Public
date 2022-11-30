open! Core
open Lib
open Galb_tmpl

(******************************************************************************)
(* CONSTANTS                                                                  *)
(******************************************************************************)

let const_COMB_N : int = 10

let const_TEMPLATE : int array array = querytpl_1076_42

let const_TEMPLATE_LEN : int = Array.length const_TEMPLATE

let const_TEMPLATE_IDX_LIMITS : int list =
   List.init const_TEMPLATE_LEN ~f:(fun i -> Array.length const_TEMPLATE.(i))

let const_SELECT_PATH_FLAG : bool = true

let const_PATH_SELECT_F : int list -> bool =
  fun nl ->
  let const_SELECTED_FRONT_PATHS : int list list =
     [
       [ 39; 268; 26; 219; 83; 88; 145 ];
       [ 39; 268; 30; 219; 83; 88; 145 ];
       [ 39; 268; 26; 219; 85; 88; 145 ];
       [ 39; 268; 30; 219; 85; 88; 145 ];
     ]
  in
  List.exists const_SELECTED_FRONT_PATHS ~f:(List.equal equal_int nl)

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

let next : int list -> (int list, int) result =
  fun il ->
  List.fold2_exn const_TEMPLATE_IDX_LIMITS il ~init:(Error 0)
    ~f:(fun acc lim cur_v ->
      match acc with
      | Ok lst  -> Ok (cur_v :: lst)
      | Error n ->
        if cur_v + 1 < lim
        then Ok ((cur_v + 1) :: List.init n ~f:(fun _ -> 0))
        else Error (n + 1)
  )
  |> function
  | Ok il        -> Ok (List.rev il)
  | Error _ as v -> v

let gen_combinations : int list -> int list list * (int list, int) result =
  fun il ->
  let rec n_acc :
      int ->
      int list list ->
      (int list, int) result ->
      int list list * (int list, int) result =
    fun n accll ind ->
    match (n, ind) with
    | (0, _)       -> (accll, ind)
    | (_, Error _) -> (accll, ind)
    | (_, Ok idx)  -> (
      match next idx with
      | Error e -> (accll, Error e)
      | Ok v    ->
        let scenario = List.mapi v ~f:(fun i k -> const_TEMPLATE.(i).(k)) in
        n_acc (n - 1) (scenario :: accll) (Ok v)
    )
  in
  n_acc const_COMB_N [] (Ok il)

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
   let _ =
      Utils.Log.debug (fun m -> m "[CONSTANTS] : COMB_N = %d" const_COMB_N)
   in
   let _ =
      Utils.Log.debug (fun m ->
          m "[CONSTANTS] : TEMPLATE_LIMIT = %s"
            (List.to_string ~f:string_of_int const_TEMPLATE_IDX_LIMITS)
      )
   in
   let gen_mstate : int list -> MState.t -> MState.t =
     fun nl ms ->
     List.fold_right nl ~init:ms ~f:(fun n ms ->
         let ss =
            Se.SSet.find_exn se_result.sr_blocked ~f:(fun ss ->
                Tz.equal_sym_state_id [ n ] ss.ss_id
            )
         in
         MState.cons ss ms
     )
   in
   let refute : int list -> unit =
      let open Refute in
      fun scenario ->
      if const_SELECT_PATH_FLAG && not (const_PATH_SELECT_F scenario)
      then ()
      else (
        let mstates : MSSet.t =
           MSSet.map se_result.sr_queries ~f:(fun qs ->
               gen_mstate scenario (MState.init qs)
           )
        in
        Refute.MSSet.iter mstates ~f:(fun ms ->
            let summary_str =
               Tz.sexp_of_sym_state_id (MState.get_summary ms).sm_s_id
               |> Sexp.to_string
            in
            match
              Refute.refute cfg.cfg_smt_ctxt cfg.cfg_smt_slvr init_strg
                { pp_mstate = ms; pp_satisfiability = None; pp_score = [] }
            with
            | (Some (_, Smt.Solver.SAT), Some mdl) ->
              Utils.Log.debug (fun m ->
                  m "%s : [SAT]\n%s" summary_str (Smt.Model.to_string mdl)
              );
              failwith "GALB_RFT FINISHED !!!"
            | (Some (_, Smt.Solver.UNKNOWN), _) ->
              Utils.Log.debug (fun m -> m "%s : [UNKNOWN]" summary_str)
            | (Some (_, Smt.Solver.UNSAT), _) ->
              Utils.Log.debug (fun m -> m "%s : [UNSAT]" summary_str)
            | (Some (_, Smt.Solver.SAT), None) ->
              Utils.Log.debug (fun m ->
                  m "%s : [ERR] SAT BUT NO MODEL EXISTS" summary_str
              )
            | (None, _) ->
              Utils.Log.debug (fun m ->
                  m "%s : [ERR] invalid Merged-State" summary_str
              )
        )
      )
   in
   let main_loop_count : int ref = ref 0 in
   let rec main_loop indice =
      let _ = incr main_loop_count in
      match indice with
      | Error _ -> debuglog "Main-Loop Escape Condition Satisfied"
      | Ok idx  ->
        let _ =
           Utils.Log.debug (fun m ->
               m "Main-Loop-Body with count=%d , indice=%s Start"
                 !main_loop_count
                 (indice
                 |> Result.sexp_of_t (List.sexp_of_t sexp_of_int) sexp_of_int
                 |> Sexp.to_string
                 )
           )
        in
        let (combinations, next_indice) = gen_combinations idx in
        let _ = List.iter combinations ~f:refute in
        let _ = debuglog "Main-Loop-Body End" in
        main_loop next_indice
   in
   let init_indice : (int list, int) result =
      Ok (List.init const_TEMPLATE_LEN ~f:(fun _ -> 0))
   in
   main_loop init_indice

(* call it like "dune exec -- galb_rft -I ./MicSE/test/testcases/KT1GALBSRLbY3iNb1P1Dzbdrx1Phu9d9f4Xv.tz -S ./MicSE/test/testcases/KT1GALBSRLbY3iNb1P1Dzbdrx1Phu9d9f4Xv.storage.tz -Z 30 -d -q 1076 42" *)
