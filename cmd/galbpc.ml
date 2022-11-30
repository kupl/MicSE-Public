open! Core
open Lib

type rmci_loc =
  | R70
  | R827
  | R862
  | R2323

type v2 = {
  qid : Tz.qid;
  loc70 : MState.t;
  loc827 : MState.t;
  loc862 : MState.t;
  loc2323 : MState.t;
}

let qres_NUM : int = 0

let string_of_rmci_loc = function
| R70   -> "R70"
| R827  -> "R827"
| R862  -> "R862"
| R2323 -> "R2323"

let rec collect_ppaths :
    all_rmcis:Tz.r_mich_cut_info list ->
    m_view:Se.SSGraph.mci_view ->
    Res.PPSet.t ->
    Res.PPSet.t =
   let open Refute in
   let expand_pp_custom :
       m_view:Se.SSGraph.mci_view ->
       mci_blacklist:Tz.r_mich_cut_info list ->
       Res.PPath.t ->
       Refute.PPSet.t =
      let open Se.SSGraph in
      let open MState in
      fun ~m_view ~mci_blacklist pp ->
      let _ = ignore mci_blacklist in
      let (pred : SSet.t) = ss_view_pred ~m_view (get_first_ss pp.pp_mstate) in
      let (ems : MSSet.t) =
         MSSet.map pred ~f:(fun ss -> cons ss pp.pp_mstate)
      in
      PPSet.map ems ~f:(fun ems ->
          {
            pp_mstate = ems;
            pp_score = [ -1 * MState.get_length ems ];
            pp_satisfiability = None;
          }
      )
   in
   let get_mci_blacklist : Res.PPSet.t -> Tz.r_mich_cut_info list =
     fun pps ->
     PPSet.fold pps ~init:[] ~f:(fun acc pp ->
         ((MState.get_first_ss pp.pp_mstate).ss_start_mci
         |> TzUtil.get_reduced_mci
         )
         :: acc
     )
     |> List.dedup_and_sort ~compare:Tz.compare_r_mich_cut_info
   in
   fun ~all_rmcis ~m_view ppset ->
   let mci_blacklist = get_mci_blacklist ppset in
   (* let _ = Utils.Log.debug (fun m -> m "mci-blacklist Print Start") in
      let _ =
         let str =
            List.map mci_blacklist ~f:(fun rmci ->
                Tz.sexp_of_r_mich_cut_info rmci |> Sexp.to_string
            )
            |> String.concat ~sep:"\n"
         in
         Utils.Log.debug (fun m -> m "\n%s" str)
      in
      let _ = Utils.Log.debug (fun m -> m "mci-blacklist Print End") in *)
   (* let _ = Utils.Log.debug (fun m -> m "current ppset size Print Start") in
      let _ = Utils.Log.debug (fun m -> m "%d" (PPSet.length ppset)) in
      let _ = Utils.Log.debug (fun m -> m "current ppset size Print End") in *)
   if List.for_all all_rmcis ~f:(fun m ->
          List.mem mci_blacklist m ~equal:Tz.equal_r_mich_cut_info
      )
   then ppset
   else
     collect_ppaths ~all_rmcis ~m_view
       (PPSet.fold ppset ~init:ppset ~f:(fun acc p ->
            PPSet.union (expand_pp_custom ~m_view ~mci_blacklist p) acc
        )
       )

let _ =
   let _ = print_endline "GALB Precondition Collection Start" in
   let _ = print_endline "ExecFlow.upto_sym_exec Start" in
   let ( (_, _, (tz_code : Tz.mich_i Tz.cc)),
         (init_strg_opt : Tz.mich_v Tz.cc option),
         (se_result : Se.se_result),
         (init_state : Tz.sym_state)
       ) =
      ExecFlow.upto_sym_exec None
   in
   let _ = Utils.Log.debug (fun m -> m "ExecFlow.upto_sym_exec End") in
   (* let _ = Utils.Log.debug (fun m -> m "blocked-state rmcis print Start") in
      let _ =
         Se.SSet.iter se_result.sr_blocked ~f:(fun ss ->
             Utils.Log.debug (fun m ->
                 let (start_rmci, block_rmci) =
                    ( TzUtil.get_reduced_mci ss.ss_start_mci,
                      TzUtil.get_reduced_mci ss.ss_block_mci
                    )
                 in
                 m "start-rmci = %s\n	                 block-rmci = %s"
                   (Tz.sexp_of_r_mich_cut_info start_rmci |> Sexp.to_string)
                   (Tz.sexp_of_r_mich_cut_info block_rmci |> Sexp.to_string)
             )
         )
      in
      let _ = Utils.Log.debug (fun m -> m "blocked-state rmcis print End") in *)
   (* let _ =
         Utils.Log.debug (fun m -> m "blocked-state rmcis dedup print Start")
      in
      let _ =
         Se.SSet.fold se_result.sr_blocked ~init:[] ~f:(fun acc ss ->
             ( ss.ss_start_mci |> TzUtil.get_reduced_mci,
               ss.ss_block_mci |> TzUtil.get_reduced_mci
             )
             :: acc
         )
         |> List.dedup_and_sort ~compare:(fun (x1, x2) (y1, y2) ->
                let c1 : int = Tz.compare_r_mich_cut_info x1 y1 in
                if c1 = 0 then Tz.compare_r_mich_cut_info x2 y2 else c1
            )
         |> List.iter ~f:(fun (x, y) ->
                Utils.Log.debug (fun m ->
                    m "start-rmci = %s\n	                 block-rmci = %s"
                      (Tz.sexp_of_r_mich_cut_info x |> Sexp.to_string)
                      (Tz.sexp_of_r_mich_cut_info y |> Sexp.to_string)
                )
            )
      in
      let _ = Utils.Log.debug (fun m -> m "blocked-state rmcis dedup print End") in *)
   let _ = Utils.Log.debug (fun m -> m "Res.init_config Start") in
   let (cfg : Res.config) =
      Res.init_config tz_code init_strg_opt se_result init_state
   in
   let _ = Utils.Log.debug (fun m -> m "Res.init_config End") in
   let _ = Utils.Log.debug (fun m -> m "Get All-RMcis Start") in
   let all_rmcis : Tz.r_mich_cut_info list =
      Se.SSet.fold se_result.sr_blocked ~init:[] ~f:(fun acc ss ->
          ss.ss_start_mci :: acc
      )
      |> List.map ~f:TzUtil.get_reduced_mci
      |> List.dedup_and_sort ~compare:Tz.compare_r_mich_cut_info
   in
   let _ = Utils.Log.debug (fun m -> m "Get All-RMcis End") in
   let _ = Utils.Log.debug (fun m -> m "Set All-RMcis Names Start") in
   let (l70, l827, l862, l2323) =
      match all_rmcis with
      | [ a; b; c; d ] -> (a, b, c, d)
      | _              -> failwith "ERR"
   in
   let _ = Utils.Log.debug (fun m -> m "Set All-RMcis Names End") in
   (* let _ =
         Utils.Log.debug (fun m -> m "Print Selected rmci (pc_TARGET_rmci) Start")
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "Selected rmci : %s"
               (Sexp.to_string (Tz.sexp_of_r_mich_cut_info pc_TARGET_rmci))
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "Print Selected rmci (pc_TARGET_rmci) End")
      in *)
   let _ = Utils.Log.debug (fun m -> m "All-RMcis Print Start") in
   let _ =
      let str =
         List.map all_rmcis ~f:(fun rmci ->
             Tz.sexp_of_r_mich_cut_info rmci |> Sexp.to_string
         )
         |> String.concat ~sep:"\n"
      in
      Utils.Log.debug (fun m -> m "\n%s" str)
   in
   let _ = Utils.Log.debug (fun m -> m "All-RMcis Print End") in
   (* let _ = Utils.Log.debug (fun m -> m "Cfg SSGraph Mview Pred Print Start") in
      let _ =
         let open Se.SSGraph in
         let mview_pred_print mview =
            RMCIMap.iteri mview ~f:(fun ~key ~data:{ pred; succ = _ } ->
                Se.SSet.iter pred ~f:(fun { ss_start_mci; ss_block_mci; _ } ->
                    Utils.Log.debug (fun m ->
                        m
                          "start-rmci = %s\n	                 block-rmci = %s\n	                 key-rmci = %s"
                          (ss_start_mci
                          |> TzUtil.get_reduced_mci
                          |> Tz.sexp_of_r_mich_cut_info
                          |> Sexp.to_string
                          )
                          (ss_block_mci
                          |> TzUtil.get_reduced_mci
                          |> Tz.sexp_of_r_mich_cut_info
                          |> Sexp.to_string
                          )
                          (key |> Tz.sexp_of_r_mich_cut_info |> Sexp.to_string)
                    )
                )
            )
         in
         mview_pred_print cfg.cfg_m_view
      in
      let _ = Utils.Log.debug (fun m -> m "Cfg SSGraph Mview Pred Print End") in *)
   let _ = Utils.Log.debug (fun m -> m "Res.init_res Start") in
   let (init_res : Res.res) = Res.init_res cfg in
   let _ = Utils.Log.debug (fun m -> m "Res.init_res End") in
   let _ =
      Utils.Log.debug (fun m -> m "cfg m_view debugging info print Start")
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
   let _ = Utils.Log.debug (fun m -> m "cfg m_view debugging info print End") in
   let _ = Utils.Log.debug (fun m -> m "1. Collect PPaths Start") in
   let ppaths_collected_res : Res.res =
      let m_view = cfg.cfg_m_view in
      {
        init_res with
        r_qr_lst =
          List.mapi init_res.r_qr_lst ~f:(fun i qr ->
              let _ =
                 Utils.Log.debug (fun m ->
                     m "  ppath_collected_res - qres index = %d" (i + 1)
                 )
              in
              {
                qr with
                Res.qr_exp_ppaths =
                  collect_ppaths ~all_rmcis ~m_view qr.qr_exp_ppaths;
              }
          );
      }
   in
   let _ = Utils.Log.debug (fun m -> m "1. Collect PPaths End") in
   (* let _ = Utils.Log.debug (fun m -> m "Collected PPath Print Start") in
      let _ =
         List.iteri ppaths_collected_res.r_qr_lst ~f:(fun qri qr ->
             let _ = Utils.Log.debug (fun m -> m "---------------------") in
             Utils.Log.debug (fun m ->
                 m "qr-index = %d\n%s" qri
                   (Refute.PPSet.fold qr.qr_exp_ppaths ~init:[] ~f:(fun acc pp ->
                        MState.get_summary pp.pp_mstate :: acc
                    )
                   |> List.map ~f:(fun summ ->
                          List.to_string ~f:string_of_int summ.MState.sm_s_id
                      )
                   |> String.concat ~sep:"\t"
                   )
             )
         )
      in
      let _ = Utils.Log.debug (fun m -> m "Collected PPath Print End") in *)
   (* let _ = ignore ppaths_collected_res in *)
   let _ =
      Utils.Log.debug (fun m -> m "1.5. Pick Qres using top-variable Start")
   in
   let qres_TARGET : Res.qres =
      List.nth_exn ppaths_collected_res.r_qr_lst qres_NUM
   in
   let _ =
      Utils.Log.debug (fun m -> m "1.5. Pick Qres using top-variable End")
   in
   let _ = Utils.Log.debug (fun m -> m "Print Total PPaths Size Start") in
   let _ =
      Utils.Log.debug (fun m ->
          m "Total PPaths NUM = %d" (Res.PPSet.length qres_TARGET.qr_exp_ppaths)
      )
   in
   let _ = Utils.Log.debug (fun m -> m "Print Total PPaths Size End") in
   let _ = Utils.Log.debug (fun m -> m "2. Pick 4 PPaths Start") in
   let qres_4PATHS : v2 =
      let open Res in
      let open Res.PPath in
      let g1 : Res.PPSet.t -> Tz.r_mich_cut_info -> Res.PPSet.t =
        fun ppset rmci ->
        let _ = Utils.Log.debug (fun m -> m "qres_4PATHS - g1 Start") in
        let filter_by_rmci =
           Res.PPSet.filter ppset ~f:(fun pp ->
               let pprmci =
                  (MState.get_first_ss pp.pp_mstate).Tz.ss_start_mci
                  |> TzUtil.get_reduced_mci
               in
               Tz.equal_r_mich_cut_info rmci pprmci
           )
        in
        let (size_pruned, _) =
           Res.PPSet.fold filter_by_rmci ~init:(Res.PPSet.empty, 5000)
             ~f:(fun (acc_set, acc_sz) pp ->
               let ppsz = MState.get_length pp.pp_mstate in
               if ppsz < acc_sz
               then (Res.PPSet.singleton pp, ppsz)
               else if ppsz = acc_sz
               then (Res.PPSet.add acc_set pp, acc_sz)
               else (acc_set, acc_sz)
           )
        in
        (* More detailed result - it uses dead-path elimination *)
        let result =
           let sz = Res.PPSet.length size_pruned in
           let rootsz : int =
              Float.round_up (float_of_int sz ** 0.5) |> int_of_float
           in
           List.foldi (size_pruned |> Res.PPSet.to_list) ~init:Res.PPSet.empty
             ~f:(fun i acc pp ->
               let _ =
                  if (i + 1) mod rootsz = 0
                  then
                    Utils.Log.debug (fun m ->
                        m
                          "qres_4PATHS - (%d / %d) th SAT checking start - [%d] are SAT)"
                          (i + 1) sz (Res.PPSet.length acc)
                    )
                  else ignore ""
               in
               let satisfiability_b : bool =
                  let vc = Vc.gen_sp_from_ms pp.pp_mstate Tz.MF_true in
                  match Vc.check_sat cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc with
                  | (Smt.Solver.SAT, _) -> true
                  | _                   -> false
               in
               if satisfiability_b then Res.PPSet.add acc pp else acc
           )
        in
        let _ =
           Utils.Log.debug (fun m ->
               m "qres_4PATHS - g1 End with collected ppaths size = %d"
                 (Res.PPSet.length result)
           )
        in
        result
      in
      let g2 : Res.PPSet.t -> MState.t =
        fun ppset ->
        (* let _ = Utils.Log.debug (fun m -> m "%d" (PPSet.length ppset)) in *)
        let scoremax_pp =
           PPSet.to_list ppset
           |> List.sort ~compare:(fun x y ->
                  compare_int
                    (MState.get_length x.pp_mstate)
                    (MState.get_length y.pp_mstate)
              )
           (* PPSet.fold ppset ~init:(PPSet.min_elt_exn ppset) ~f:(fun acc pp ->
                  if MState.get_length acc.pp_mstate
                     < MState.get_length pp.pp_mstate
                  then pp
                  else acc
              ) *)
           |> List.hd_exn
        in
        scoremax_pp.pp_mstate
      in
      let { qr_qid; qr_exp_ppaths; _ } = qres_TARGET in
      {
        qid = qr_qid;
        loc70 = g1 qr_exp_ppaths l70 |> g2;
        loc827 = g1 qr_exp_ppaths l827 |> g2;
        loc862 = g1 qr_exp_ppaths l862 |> g2;
        loc2323 = g1 qr_exp_ppaths l2323 |> g2;
      }
   in
   let _ = Utils.Log.debug (fun m -> m "2. Pick 4 PPaths End") in
   let _ = Utils.Log.debug (fun m -> m "Print qres-num (qres_NUM) Start") in
   let _ = Utils.Log.debug (fun m -> m "qres_NUM = %d" qres_NUM) in
   let _ = Utils.Log.debug (fun m -> m "Print qres-num (qres_NUM) End") in
   let _ = Utils.Log.debug (fun m -> m "Print 4 PPaths Start") in
   let _ =
      let mstate_str mst : string =
         mst |> MState.get_summary |> MState.sexp_of_summary |> Sexp.to_string
      in
      let { qid; loc70; loc827; loc862; loc2323 } = qres_4PATHS in
      Utils.Log.debug (fun m ->
          m "qid = %s\nloc70 = %s\nloc827 = %s\nloc862 = %s\nloc2323=%s\n"
            (Sexp.to_string (Tz.sexp_of_qid qid))
            (mstate_str loc70) (mstate_str loc827) (mstate_str loc862)
            (mstate_str loc2323)
      )
   in
   let _ = Utils.Log.debug (fun m -> m "Print 4 PPaths End") in
   (*********************************************************************)
   (*********************************************************************)
   (***************** R70    ********************************************)
   (*********************************************************************)
   (*********************************************************************)
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R70 Start") in
   let _ =
      let pc_TARGET : rmci_loc = R70 in
      let pc_TARGET_rmci : Tz.r_mich_cut_info =
         match pc_TARGET with
         | R70   -> l70
         | R827  -> l827
         | R862  -> l862
         | R2323 -> l2323
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - qres_NUM = %d, target-rmci = %s" qres_NUM
               (string_of_rmci_loc pc_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates Start")
      in
      let cands_TARGET : Inv.CSet.t =
         let cands : Inv.cands =
            Inv.RMCIMap.find_exn ppaths_collected_res.r_cands pc_TARGET_rmci
         in
         Inv.CMap.fold cands ~init:Inv.CSet.empty ~f:(fun ~key ~data:_ acc ->
             Inv.CSet.add acc key
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size Start"
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Candidate Size : %d"
               (Inv.CSet.length cands_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size End"
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates End")
      in
      let path =
         match pc_TARGET with
         | R70   -> qres_4PATHS.loc70
         | R827  -> qres_4PATHS.loc827
         | R862  -> qres_4PATHS.loc862
         | R2323 -> qres_4PATHS.loc2323
      in
      let f cand =
         let vc = Vc.gen_precond_vc cand path in
         match Vc.check_val cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc with
         | (Smt.Solver.VAL, _) ->
           let _ =
              Utils.Log.debug (fun m ->
                  m "%s"
                    (Inv.sexp_of_cand cand
                    |> SexpUtil.tz_remove_ctx_i_ctx_v
                    |> SexpUtil.tz_cc_sexp_form
                    |> Sexp.to_string
                    )
              )
           in
           true
         | _                   -> false
      in
      let sz = Inv.CSet.length cands_TARGET in
      let rootsz : int =
         Float.round_up (float_of_int sz ** 0.5) |> int_of_float
      in
      let result =
         List.foldi (cands_TARGET |> Inv.CSet.to_list) ~init:Inv.CSet.empty
           ~f:(fun i acc c ->
             let _ =
                if (i + 1) mod rootsz = 0
                then
                  Utils.Log.debug (fun m ->
                      m
                        "PRECOND SEARCH - (%d / %d) th Precond Search Start - [%d] are VAL)"
                        (i + 1) sz (Inv.CSet.length acc)
                  )
                else ()
             in
             if f c then Inv.CSet.add acc c else acc
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "Total %d preconditions found" (Inv.CSet.length result)
         )
      in
      ()
   in
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R70 End") in
   (*********************************************************************)
   (*********************************************************************)
   (***************** R827   ********************************************)
   (*********************************************************************)
   (*********************************************************************)
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R827 Start") in
   let _ =
      let pc_TARGET : rmci_loc = R827 in
      let pc_TARGET_rmci : Tz.r_mich_cut_info =
         match pc_TARGET with
         | R70   -> l70
         | R827  -> l827
         | R862  -> l862
         | R2323 -> l2323
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - qres_NUM = %d, target-rmci = %s" qres_NUM
               (string_of_rmci_loc pc_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates Start")
      in
      let cands_TARGET : Inv.CSet.t =
         let cands : Inv.cands =
            Inv.RMCIMap.find_exn ppaths_collected_res.r_cands pc_TARGET_rmci
         in
         Inv.CMap.fold cands ~init:Inv.CSet.empty ~f:(fun ~key ~data:_ acc ->
             Inv.CSet.add acc key
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size Start"
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Candidate Size : %d"
               (Inv.CSet.length cands_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size End"
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates End")
      in
      let path =
         match pc_TARGET with
         | R70   -> qres_4PATHS.loc70
         | R827  -> qres_4PATHS.loc827
         | R862  -> qres_4PATHS.loc862
         | R2323 -> qres_4PATHS.loc2323
      in
      let f cand =
         let vc = Vc.gen_precond_vc cand path in
         match Vc.check_val cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc with
         | (Smt.Solver.VAL, _) ->
           let _ =
              Utils.Log.debug (fun m ->
                  m "%s"
                    (Inv.sexp_of_cand cand
                    |> SexpUtil.tz_remove_ctx_i_ctx_v
                    |> SexpUtil.tz_cc_sexp_form
                    |> Sexp.to_string
                    )
              )
           in
           true
         | _                   -> false
      in
      let sz = Inv.CSet.length cands_TARGET in
      let rootsz : int =
         Float.round_up (float_of_int sz ** 0.5) |> int_of_float
      in
      let result =
         List.foldi (cands_TARGET |> Inv.CSet.to_list) ~init:Inv.CSet.empty
           ~f:(fun i acc c ->
             let _ =
                if (i + 1) mod rootsz = 0
                then
                  Utils.Log.debug (fun m ->
                      m
                        "PRECOND SEARCH - (%d / %d) th Precond Search Start - [%d] are VAL)"
                        (i + 1) sz (Inv.CSet.length acc)
                  )
                else ()
             in
             if f c then Inv.CSet.add acc c else acc
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "Total %d preconditions found" (Inv.CSet.length result)
         )
      in
      ()
   in
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R827 End") in
   (*********************************************************************)
   (*********************************************************************)
   (***************** R862    ********************************************)
   (*********************************************************************)
   (*********************************************************************)
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R862 Start") in
   let _ =
      let pc_TARGET : rmci_loc = R862 in
      let pc_TARGET_rmci : Tz.r_mich_cut_info =
         match pc_TARGET with
         | R70   -> l70
         | R827  -> l827
         | R862  -> l862
         | R2323 -> l2323
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - qres_NUM = %d, target-rmci = %s" qres_NUM
               (string_of_rmci_loc pc_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates Start")
      in
      let cands_TARGET : Inv.CSet.t =
         let cands : Inv.cands =
            Inv.RMCIMap.find_exn ppaths_collected_res.r_cands pc_TARGET_rmci
         in
         Inv.CMap.fold cands ~init:Inv.CSet.empty ~f:(fun ~key ~data:_ acc ->
             Inv.CSet.add acc key
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size Start"
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Candidate Size : %d"
               (Inv.CSet.length cands_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size End"
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates End")
      in
      let path =
         match pc_TARGET with
         | R70   -> qres_4PATHS.loc70
         | R827  -> qres_4PATHS.loc827
         | R862  -> qres_4PATHS.loc862
         | R2323 -> qres_4PATHS.loc2323
      in
      let f cand =
         let vc = Vc.gen_precond_vc cand path in
         match Vc.check_val cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc with
         | (Smt.Solver.VAL, _) ->
           let _ =
              Utils.Log.debug (fun m ->
                  m "%s"
                    (Inv.sexp_of_cand cand
                    |> SexpUtil.tz_remove_ctx_i_ctx_v
                    |> SexpUtil.tz_cc_sexp_form
                    |> Sexp.to_string
                    )
              )
           in
           true
         | _                   -> false
      in
      let sz = Inv.CSet.length cands_TARGET in
      let rootsz : int =
         Float.round_up (float_of_int sz ** 0.5) |> int_of_float
      in
      let result =
         List.foldi (cands_TARGET |> Inv.CSet.to_list) ~init:Inv.CSet.empty
           ~f:(fun i acc c ->
             let _ =
                if (i + 1) mod rootsz = 0
                then
                  Utils.Log.debug (fun m ->
                      m
                        "PRECOND SEARCH - (%d / %d) th Precond Search Start - [%d] are VAL)"
                        (i + 1) sz (Inv.CSet.length acc)
                  )
                else ()
             in
             if f c then Inv.CSet.add acc c else acc
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "Total %d preconditions found" (Inv.CSet.length result)
         )
      in
      ()
   in
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R862 End") in
   (*********************************************************************)
   (*********************************************************************)
   (***************** R2323  ********************************************)
   (*********************************************************************)
   (*********************************************************************)
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R2323 Start") in
   let _ =
      let pc_TARGET : rmci_loc = R2323 in
      let pc_TARGET_rmci : Tz.r_mich_cut_info =
         match pc_TARGET with
         | R70   -> l70
         | R827  -> l827
         | R862  -> l862
         | R2323 -> l2323
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - qres_NUM = %d, target-rmci = %s" qres_NUM
               (string_of_rmci_loc pc_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates Start")
      in
      let cands_TARGET : Inv.CSet.t =
         let cands : Inv.cands =
            Inv.RMCIMap.find_exn ppaths_collected_res.r_cands pc_TARGET_rmci
         in
         Inv.CMap.fold cands ~init:Inv.CSet.empty ~f:(fun ~key ~data:_ acc ->
             Inv.CSet.add acc key
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size Start"
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Candidate Size : %d"
               (Inv.CSet.length cands_TARGET)
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "PRECOND SEARCH - Print Candidates Size End"
         )
      in
      let _ =
         Utils.Log.debug (fun m -> m "PRECOND SEARCH - Get Candidates End")
      in
      let path =
         match pc_TARGET with
         | R70   -> qres_4PATHS.loc70
         | R827  -> qres_4PATHS.loc827
         | R862  -> qres_4PATHS.loc862
         | R2323 -> qres_4PATHS.loc2323
      in
      let f cand =
         let vc = Vc.gen_precond_vc cand path in
         match Vc.check_val cfg.cfg_smt_ctxt cfg.cfg_smt_slvr vc with
         | (Smt.Solver.VAL, _) ->
           let _ =
              Utils.Log.debug (fun m ->
                  m "%s"
                    (Inv.sexp_of_cand cand
                    |> SexpUtil.tz_remove_ctx_i_ctx_v
                    |> SexpUtil.tz_cc_sexp_form
                    |> Sexp.to_string
                    )
              )
           in
           true
         | _                   -> false
      in
      let sz = Inv.CSet.length cands_TARGET in
      let rootsz : int =
         Float.round_up (float_of_int sz ** 0.5) |> int_of_float
      in
      let result =
         List.foldi (cands_TARGET |> Inv.CSet.to_list) ~init:Inv.CSet.empty
           ~f:(fun i acc c ->
             let _ =
                if (i + 1) mod rootsz = 0
                then
                  Utils.Log.debug (fun m ->
                      m
                        "PRECOND SEARCH - (%d / %d) th Precond Search Start - [%d] are VAL)"
                        (i + 1) sz (Inv.CSet.length acc)
                  )
                else ()
             in
             if f c then Inv.CSet.add acc c else acc
         )
      in
      let _ =
         Utils.Log.debug (fun m ->
             m "Total %d preconditions found" (Inv.CSet.length result)
         )
      in
      ()
   in
   let _ = Utils.Log.debug (fun m -> m "3. Find Preconditions R2323 End") in
   ()
