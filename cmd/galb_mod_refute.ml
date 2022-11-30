open! Core
open Lib

(******************************************************************************)
(* CONSTANTS                                                                  *)
(******************************************************************************)

let const_INTERNAL_PATHLEN_N = 5

let const_PATH_SELECT_N = 8

let const_SCORE_MAX_COEF = 1000000

let const_LEN_PENALTY = 10000

let const_PRECOND_COUNT_PENALTY = ref 10000

let const_PRECOND_LST_MAXLEN = 8

(******************************************************************************)
(* UTILITIES                                                                  *)
(******************************************************************************)

let debuglog s = Utils.Log.debug (fun m -> m "%s" s)

(******************************************************************************)
(* MAIN FUNCTION                                                              *)
(******************************************************************************)

let score_policy : int list -> float =
  fun il ->
  let len = List.length il in
  let len_penalty = len * const_LEN_PENALTY in
  List.fold il ~init:0 ~f:( + )
  |> float_of_int
  |> (fun x -> x /. float_of_int len)
  |> (fun x -> x -. float_of_int len_penalty)

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
      Res.init_config tz_code init_strg_opt se_result init_state
   in
   let _ = debuglog "init_config_custom End" in
   let _ = debuglog "init_res Start" in
   let (init_res : Res.res) = Res.init_res cfg in
   let _ = debuglog "init_res End" in
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
   let _ = ignore gen_mstate in
   let gen_path_ms : int list -> MState.t =
     fun l ->
     let (hl, last) =
        List.split_n l (List.length l - 1) |> (fun (x, y) -> (x, List.hd_exn y))
     in
     let ms = gen_mstate hl (find_block_ss last |> MState.init) in
     ms
   in
   let gen_path_sat_vc : int list -> Tz.mich_f =
     (fun l -> Vc.gen_sp_from_ms (gen_path_ms l) Tz.MF_true)
   in
   let is_trx_entry_path_exn : int list -> bool =
     fun l ->
     List.hd_exn l
     |> find_block_ss
     |> fun ss ->
     ss.ss_start_mci.mci_cutcat
     |> TzUtil.get_reduced_mcc
     |> Tz.equal_r_mich_cut_category Tz.RMCC_trx
   in
   let is_trx_exit_path_exn : int list -> bool =
     fun l ->
     List.last_exn l
     |> find_block_ss
     |> fun ss ->
     ss.ss_block_mci.mci_cutcat
     |> TzUtil.get_reduced_mcc
     |> Tz.equal_r_mich_cut_category Tz.RMCC_trx
   in
   let _ = debuglog "Gerating Trx Paths Start" in
   let gen_trx_paths : int list list -> int list list =
     fun qstates ->
     let rec folding : int list list -> int list list -> int list list =
       fun worklist acc ->
       let (notyet_l, tpath_l) : int list list * int list list =
          List.fold_left worklist ~init:([], []) ~f:(fun (acc_ny, acc_tp) p ->
              let pred_sids : int list =
                 Se.SSGraph.ss_view_pred ~m_view:cfg.cfg_m_view
                   (List.hd_exn p |> find_block_ss)
                 |> Se.SSet.fold ~init:[] ~f:(fun acc_sids ss ->
                        List.hd_exn ss.ss_id :: acc_sids
                    )
              in
              List.map pred_sids ~f:(fun sid -> sid :: p)
              |> List.partition_tf ~f:(fun l -> is_trx_entry_path_exn l |> not)
              |> (fun (ny, tp) -> (ny @ acc_ny, tp @ acc_tp))
          )
       in
       let notyet_l_len_filtered : int list list =
          List.filter notyet_l ~f:(fun l ->
              List.length l < const_INTERNAL_PATHLEN_N
          )
       in
       match notyet_l_len_filtered with
       | [] -> tpath_l @ acc
       | _  -> folding notyet_l_len_filtered (tpath_l @ acc)
     in
     folding qstates []
   in
   let trx_paths : int list list =
      let init_ss_ids =
         Se.SSet.fold se_result.sr_blocked ~init:[] ~f:(fun acc ss ->
             ss.ss_id :: acc
         )
      in
      let (tp, ny) =
         List.partition_tf init_ss_ids ~f:(fun l ->
             is_trx_entry_path_exn l && is_trx_exit_path_exn l
         )
      in
      let all_combinations =
         tp
         @ gen_trx_paths
             (List.filter ny ~f:(fun l ->
                  is_trx_exit_path_exn l && not (is_trx_entry_path_exn l)
              )
             )
      in
      let _ = debuglog "  filter valid combinations Start" in
      let valid_combinations =
         List.filter all_combinations ~f:(fun l ->
             let vc = gen_path_sat_vc l in
             Vc.check_sat cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc
             |> fst
             |> Smt.Solver.is_sat
         )
      in
      let _ = debuglog "  filter valid combinations End" in
      valid_combinations
   in
   let _ = debuglog "Gerating Trx Paths End" in
   let _ =
      Utils.Log.debug (fun m -> m "TrxPaths : %d" (List.length trx_paths))
   in
   let _ =
      List.iter trx_paths ~f:(fun p ->
          Utils.Log.debug (fun m -> m "  %s" (List.to_string p ~f:string_of_int))
      )
   in
   let _ = debuglog "Calculate PreservationMap Start" in
   let trx_cands : Inv.cand list =
      Inv.RMCIMap.find_exn init_res.r_cands
        (init_state.ss_start_mci |> TzUtil.get_reduced_mci)
      |> Inv.CMap.keys
   in
   let _ =
      const_PRECOND_COUNT_PENALTY :=
        const_SCORE_MAX_COEF / List.length trx_cands
   in
   let prsv_map : int list list Inv.CMap.t =
      let dbg_counter : int ref = ref 0 in
      List.fold_left trx_cands ~init:Inv.CMap.empty ~f:(fun accm c ->
          let _ =
             incr dbg_counter;
             if !dbg_counter
                mod (List.length trx_cands
                    |> float_of_int
                    |> sqrt
                    |> int_of_float
                    |> succ
                    )
                = 0
             then
               Utils.Log.debug (fun m ->
                   m "  cands progress : %d / %d" !dbg_counter
                     (List.length trx_cands)
               )
             else ()
          in
          Inv.CMap.add_exn accm ~key:c
            ~data:
              (List.filter trx_paths ~f:(fun path ->
                   let ms = gen_path_ms path in
                   let vc = Vc.gen_preservation_vc c ms in
                   Vc.check_val cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc
                   |> fst
                   |> Smt.Solver.is_val
               )
              )
      )
   in
   let _ = ignore prsv_map in
   (* let _ =
         List.iter trx_cands ~f:(fun c ->
             Utils.Log.debug (fun m ->
                 m "  cand : (%d) : %s\n  paths : %s"
                   (Inv.CMap.find_exn prsv_map c |> List.length)
                   (c.c_fmla |> Inv.MFSet.sexp_of_t |> SexpUtil.to_string)
                   (Inv.CMap.find_exn prsv_map c
                   |> List.to_string ~f:(List.to_string ~f:string_of_int)
                   )
             )
         )
      in *)
   let _ = debuglog "Calculate PreservationMap End" in
   let _ = debuglog "Make query states to last-transaction paths Start" in
   let init_res =
      let rec gen_qpaths : MState.t list -> MState.t list -> MState.t list =
        fun acc ms_wl ->
        if List.is_empty ms_wl
        then acc
        else (
          let (cp, ny) : MState.t list * MState.t list =
             List.partition_tf ms_wl ~f:(fun ms ->
                 is_trx_entry_path_exn (MState.get_summary ms).sm_s_id
             )
          in
          let ny : MState.t list =
             List.filter ny ~f:(fun ms ->
                 MState.get_length ms < const_INTERNAL_PATHLEN_N
             )
          in
          gen_qpaths
            ((* cp-add *) cp @ acc)
            ((* ny-expand *)
             List.fold_left ny ~init:[] ~f:(fun acc ms ->
                 let pred_sset : Se.SSet.t =
                    Se.SSGraph.ss_view_pred ~m_view:cfg.cfg_m_view
                      (MState.get_first_ss ms)
                 in
                 let r =
                    Se.SSet.fold pred_sset ~init:[] ~f:(fun acc ss ->
                        MState.cons ss ms :: acc
                    )
                 in
                 r @ acc
             )
            )
        )
      in
      let qreslst : Res.qres list =
         let open Res.PPath in
         List.map init_res.r_qr_lst ~f:(fun qres ->
             let exp_pp : Res.PPath.t list =
                Res.PPSet.fold qres.qr_exp_ppaths ~init:[] ~f:(fun acc qs ->
                    let expanded_ms : MState.t list =
                       gen_qpaths [] [ qs.pp_mstate ]
                       |> List.filter ~f:(fun ms ->
                              Vc.check_sat cfg.cfg_smt_ctxt cfg.cfg_smt_slvr
                                (Vc.gen_sp_from_ms ms Tz.MF_true)
                              |> fst
                              |> Smt.Solver.is_sat
                          )
                    in
                    let expanded : Res.PPath.t list =
                       List.map expanded_ms ~f:(fun ms ->
                           {
                             pp_mstate = ms;
                             pp_satisfiability = None;
                             pp_score =
                               [ const_SCORE_MAX_COEF / List.length trx_paths ];
                           }
                       )
                    in
                    expanded @ acc
                )
                |> fun lst ->
                let len = List.length lst in
                List.map lst ~f:(fun pp ->
                    { pp with pp_score = [ List.hd_exn pp.pp_score / len ] }
                )
             in
             { qres with qr_exp_ppaths = Res.PPSet.of_list exp_pp }
         )
      in
      { init_res with r_qr_lst = qreslst }
   in
   let _ = debuglog "Make query states to last-transaction paths End" in
   let _ =
      debuglog "expanded_ppset lengths : ";
      List.iter init_res.r_qr_lst ~f:(fun qres ->
          Utils.Log.debug (fun m ->
              m "  %d : %s"
                (Res.PPSet.length qres.qr_exp_ppaths)
                (qres.qr_qid |> Tz.sexp_of_qid |> SexpUtil.to_string)
          )
      )
   in
   let rec refuter_turn : Res.config -> Res.qres -> unit =
      let open Res.PPath in
      let run_count = ref 0 in
      fun cfg qres ->
      if Utils.Time.is_timeout cfg.cfg_timer
      then ()
      else (
        let _ =
           Utils.Log.debug (fun m ->
               m "Run-Count : %d  \tExpanding PPaths : %d"
                 ( incr run_count;
                   !run_count
                 )
                 (Res.PPSet.length qres.qr_exp_ppaths)
           )
        in
        (* 1. select score top-n paths *)
        let top_score_paths : Res.PPath.t list =
           Res.PPSet.to_list qres.qr_exp_ppaths
           |> List.sort ~compare:(fun x y ->
                  compare_float (score_policy y.pp_score)
                    (score_policy x.pp_score)
              )
           |> (fun l -> List.take l const_PATH_SELECT_N)
        in
        let _ =
           debuglog "Selected Paths : ";
           List.iter top_score_paths ~f:(fun p ->
               Utils.Log.debug (fun m ->
                   m "  PATH : %s  \tSCORE : %d -- %s"
                     ((MState.get_summary p.pp_mstate).sm_s_id
                     |> List.to_string ~f:string_of_int
                     )
                     (score_policy p.pp_score |> int_of_float)
                     (p.pp_score |> List.to_string ~f:string_of_int)
               )
           )
        in
        (* 2. expand selected paths and try to refute. if bug found, print it and return. *)
        let expanded_ppaths : Res.PPath.t list =
           List.fold top_score_paths ~init:[] ~f:(fun acc qp ->
               let preconds : Inv.cand list =
                  List.filter trx_cands ~f:(fun c ->
                      let vc = Vc.gen_precond_vc c qp.pp_mstate in
                      Vc.check_val cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc
                      |> fst
                      |> Smt.Solver.is_val
                  )
                  |> List.filter ~f:(fun c ->
                         Inv.CMap.find_exn prsv_map c
                         |> (fun lst -> List.is_empty lst |> not)
                     )
               in
               let preconds_dup_removed : Inv.cand list =
                  List.fold preconds ~init:([], [])
                    ~f:(fun (acc_pc_l, acc_path_l) c ->
                      let pl = Inv.CMap.find_exn prsv_map c in
                      if List.mem acc_path_l pl ~equal:(fun x y ->
                             List.equal
                               (fun a b -> List.equal Int.equal a b)
                               x y
                         )
                      then (acc_pc_l, acc_path_l)
                      else (c :: acc_pc_l, pl :: acc_path_l)
                  )
                  |> fst
               in
               let _ =
                  Utils.Log.debug (fun m ->
                      m "  # of Precondition-dup-removed : %d"
                        (List.length preconds_dup_removed)
                  )
               in
               let selected_precond : Inv.cand =
                  let special_preconditions =
                     List.sort preconds_dup_removed ~compare:(fun c1 c2 ->
                         compare_int
                           (Inv.CMap.find_exn prsv_map c1 |> List.length)
                           (Inv.CMap.find_exn prsv_map c2 |> List.length)
                     )
                     |> (fun l -> List.take l const_PRECOND_LST_MAXLEN)
                  in
                  List.nth_exn special_preconditions
                    (Random.int (List.length special_preconditions))
               in
               let tp_score : int list -> int =
                 fun tp ->
                 let safe_paths = Inv.CMap.find_exn prsv_map selected_precond in
                 if List.mem safe_paths tp ~equal:(List.equal Int.equal)
                 then 0
                 else
                   float_of_int
                     (const_SCORE_MAX_COEF
                     - (!const_PRECOND_COUNT_PENALTY * List.length preconds)
                     )
                   /. float_of_int (List.length safe_paths)
                   |> int_of_float
                 (* float_of_int const_SCORE_MAX_COEF
                    /. float_of_int (List.length safe_paths)
                    |> int_of_float
                    |> fun x ->
                    x - (!const_PRECOND_COUNT_PENALTY * List.length preconds) *)
               in
               let expanded =
                  List.map trx_paths ~f:(fun tp ->
                      let ms =
                         List.fold_right tp ~init:qp.pp_mstate ~f:(fun t acc ->
                             MState.cons (find_block_ss t) acc
                         )
                      in
                      {
                        pp_score = tp_score tp :: qp.pp_score;
                        pp_satisfiability = None;
                        pp_mstate = ms;
                      }
                  )
               in
               let expanded_sat =
                  List.filter expanded ~f:(fun pp ->
                      let vc = Vc.gen_sp_from_ms pp.pp_mstate Tz.MF_true in
                      Vc.check_sat cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc
                      |> fst
                      |> Smt.Solver.is_sat
                  )
               in
               expanded_sat @ acc
           )
        in
        let result : Res.PPath.t option =
           List.fold expanded_ppaths ~init:None ~f:(fun acc p ->
               if Option.is_some acc
               then acc
               else (
                 let vc = Vc.gen_refute_vc init_strg p.pp_mstate in
                 let r =
                    Vc.check_sat cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc
                    |> fst
                    |> Smt.Solver.is_sat
                 in
                 if r then Some p else None
               )
           )
        in
        match result with
        | Some p ->
          Utils.Log.debug (fun m ->
              m "\n<<<< REFUTED >>>>\n%s : %s"
                (List.to_string ~f:string_of_int
                   (MState.get_summary p.pp_mstate).sm_s_id
                )
                (List.to_string ~f:string_of_int p.pp_score)
          )
        | None   ->
          refuter_turn cfg
            {
              qres with
              qr_exp_ppaths =
                Res.PPSet.union
                  (Res.PPSet.of_list expanded_ppaths)
                  (Res.PPSet.diff qres.qr_exp_ppaths
                     (Res.PPSet.of_list top_score_paths)
                  );
            }
      )
   in
   List.iter init_res.r_qr_lst ~f:(fun qr -> refuter_turn cfg qr)
