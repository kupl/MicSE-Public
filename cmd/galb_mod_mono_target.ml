open! Core
open Lib

(******************************************************************************)
(* CONSTANTS                                                                  *)
(******************************************************************************)

let const_INTERNAL_PATHLEN_N = 5

let const_PATH_SELECT_N = 10

let const_PRECOND_LST_MAXLEN = 8

let const_LENGTH_PENALTY = 0.005

(* PROCESS_A makes BALANCE < (fee_acc + total_deposit) *)
let const_PROCESS_A : int list list =
   [ [ 0 ]; [ 9 ]; [ 10 ]; [ 12; 13; 14; 15 ]; [ 17; 19; 20; 23 ] ]

(* PROCESS_B makes BALANCE < total_deposit *)
let const_PROCESS_B : int list list = const_PROCESS_A @ [ [ 4 ]; [ 8 ] ]

let const_TARGET_SCENARIO : int list list =
   const_PROCESS_A @ [ [ 12; 13; 14; 15 ] ]

(******************************************************************************)
(* UTILITIES                                                                  *)
(******************************************************************************)

let debuglog s = Utils.Log.debug (fun m -> m "%s" s)

(******************************************************************************)
(* MAIN FUNCTION                                                              *)
(******************************************************************************)

let trx_cands_INFO : Inv.cand list ref = ref []

let preconds_MAP : (int list, Inv.cand list) Map.Poly.t ref = ref Map.Poly.empty

let preconds_MAP_ADD : int list -> Inv.cand list -> unit =
  (fun il cl -> preconds_MAP := Map.Poly.add_exn !preconds_MAP ~key:il ~data:cl)

let preconds_MAP_SEE : int list -> Inv.cand list =
  fun il ->
  Map.Poly.find !preconds_MAP il |> Option.value ~default:!trx_cands_INFO

let score_policy : int list -> float =
  fun il ->
  let len = List.length il in
  List.fold il ~init:0 ~f:( + )
  |> float_of_int
  |> (fun x -> x /. float_of_int len)
  |> (fun x -> x -. (const_LENGTH_PENALTY *. float_of_int len))

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
   let _ = ignore init_strg in
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
   let rec get_trx_path : int list -> int list =
     fun il ->
     match il with
     | []     -> il
     | h :: t ->
       if Tz.equal_r_mich_cut_category
            ((find_block_ss h).ss_start_mci.mci_cutcat |> TzUtil.get_reduced_mcc)
            Tz.RMCC_trx
       then il
       else get_trx_path t
   in
   let trx_cands : Inv.cand list =
      Inv.RMCIMap.find_exn init_res.r_cands
        (init_state.ss_start_mci |> TzUtil.get_reduced_mci)
      |> Inv.CMap.keys
   in
   let _ = trx_cands_INFO := trx_cands in
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
                             pp_score = [ 1 ];
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
   let rec target_turn : Res.config -> Res.PPath.t -> int list list -> unit =
      let open Res.PPath in
      fun cfg pp scenario ->
      let _ =
         Utils.Log.debug (fun m ->
             m "  PATH : %s  \tSCORE : %f -- %s"
               ((MState.get_summary pp.pp_mstate).sm_s_id
               |> List.to_string ~f:string_of_int
               )
               (score_policy pp.pp_score)
               (pp.pp_score |> List.to_string ~f:string_of_int)
         )
      in
      match scenario with
      | []           -> ()
      | head :: tail ->
        let ms = gen_mstate head pp.pp_mstate in
        let qp_summary : int list = (MState.get_summary pp.pp_mstate).sm_s_id in
        let previous_preconds : Inv.cand list =
           preconds_MAP_SEE (get_trx_path (List.tl_exn qp_summary))
        in
        let preconds : Inv.cand list =
           List.filter previous_preconds ~f:(fun c ->
               let vc = Vc.gen_precond_vc c pp.pp_mstate in
               Vc.check_val cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc
               |> fst
               |> Smt.Solver.is_val
           )
        in
        let _ = preconds_MAP_ADD qp_summary preconds in
        let _ =
           Utils.Log.debug (fun m ->
               m "  # of Survived Preconditions : %d / %d" (List.length preconds)
                 (List.length previous_preconds)
           )
        in
        let tp_score : int =
           if List.length previous_preconds - List.length preconds = 0
           then 0
           else 1
        in
        target_turn cfg
          {
            pp_mstate = ms;
            pp_satisfiability = None;
            pp_score = tp_score :: pp.pp_score;
          }
          tail
   in
   List.iter init_res.r_qr_lst ~f:(fun qr ->
       Res.PPSet.iter qr.qr_exp_ppaths ~f:(fun pp ->
           target_turn cfg pp (List.rev const_TARGET_SCENARIO)
       )
   )
