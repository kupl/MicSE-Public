(* Coop : Cooperation model for MicSE-Synergetic *)

exception CoopError of string

open! Core

(******************************************************************************)
(******************************************************************************)
(* Common Datatypes                                                           *)
(******************************************************************************)
(******************************************************************************)

(* Set of Tz.qid *)
module QIDSet = Set.Make (Tz.QId_cmp)

(* Set of Res.PPath.t *)
module PPSet = Set.Make (Res.PPath)

(* Set of Inv.cand *)
module CSet = Set.Make (Inv.Cand_cmp)

(* Map of MState.summary *)
module SMYMap = Map.Make (MState.SMY_cmp)

(******************************************************************************)
(******************************************************************************)
(* Cooperation                                                                *)
(******************************************************************************)
(******************************************************************************)

let precond_search :
    int ->
    Smt.Ctx.t ->
    Smt.Solver.t ->
    Inv.inv_map ->
    Tz.qid ->
    PPSet.t ->
    Inv.cand_map * CSet.t SMYMap.t ->
    Inv.cand_map * CSet.t SMYMap.t =
   let open Tz in
   let open Inv in
   let open Res in
   let open PPath in
   let open Smt in
   let open Vc in
   let open MState in
   let get_cands :
       cand_map * CSet.t SMYMap.t -> inv_map -> PPath.t -> qid -> cand list =
     fun (cmap, pmap) imap ppath qid ->
     let (rmci : Tz.r_mich_cut_info) =
        (MState.get_first_ss ppath.pp_mstate).ss_start_mci
        |> TzUtil.get_reduced_mci
     in
     if equal_r_mich_cut_category rmci.rmci_cutcat RMCC_trx
     then (
       let (surfix : MState.t option) =
          MState.get_last_trx_ms ppath.pp_mstate
       in
       if Option.is_none surfix
       then find_cand_by_rmci cmap rmci |> CMap.to_alist |> List.map ~f:fst
       else
         SMYMap.find pmap (MState.get_summary (Option.value_exn surfix))
         |> function
         | None      ->
           find_cand_by_rmci cmap rmci |> CMap.to_alist |> List.map ~f:fst
         | Some cset ->
           let (cur_inv : cand) = find_inv_by_rmci imap rmci in
           let (str_clst : cand list) =
              cset
              |> CSet.map ~f:(fun cand -> join_cands cur_inv cand)
              |> CSet.filter ~f:(fun cand ->
                     mem_by_rmci cmap ~key:rmci ~value:cand
                 )
              |> CSet.to_list
           in
           str_clst
     )
     else
       find_ordered_cand_by_rmci cmap rmci qid ~order:`Increasing
         ~remove_unflaged:true ~remove_not_precond:true
     (* inner-function get_cands end *)
   in
   let update_cmap_and_pmap :
       Smt.Ctx.t ->
       Smt.Solver.t ->
       PPath.t ->
       qid ->
       cand list ->
       cand_map * CSet.t SMYMap.t ->
       cand_map * CSet.t SMYMap.t =
     fun ctx slvr ppath qid cands (cmap, pmap) ->
     let (rmci : Tz.r_mich_cut_info) =
        (MState.get_first_ss ppath.pp_mstate).ss_start_mci
        |> TzUtil.get_reduced_mci
     in
     List.fold cands ~init:(cmap, pmap) ~f:(fun (cmap', pmap') cand ->
         let (vc : mich_f) =
            gen_precond_vc cand ppath.pp_mstate |> TzUtil.opt_mf
         in
         let ((vld : Solver.validity), _) = check_val ctx slvr vc in
         let ((point : int * int), (updated_pmap' : CSet.t SMYMap.t)) =
            match vld with
            | VAL     ->
              let (updated_pmap' : CSet.t SMYMap.t) =
                 if equal_r_mich_cut_category rmci.rmci_cutcat RMCC_trx
                 then (
                   let (summary : summary) = get_summary ppath.pp_mstate in
                   SMYMap.update pmap' summary ~f:(function
                   | Some cset -> CSet.add cset cand
                   | None      -> CSet.singleton cand
                   )
                 )
                 else pmap'
              in
              ((1, 0), updated_pmap')
            | INVAL   -> ((0, 1), pmap')
            | UNKNOWN -> ((0, 1), pmap')
         in
         let (updated_cmap' : cand_map) =
            update_score_by_rmci cmap' ~key:rmci ~value:cand ~qid ~point
         in
         (updated_cmap', updated_pmap')
     )
     (* inner-function update_cmap_and_pmap end *)
   in
   fun picked ctx slvr imap qid tpaths (cmap, pmap) ->
   let _ = ignore picked in
   PPSet.fold tpaths ~init:(cmap, pmap) ~f:(fun (cmap', pmap') tpath ->
       let (plst : PPath.t list) = PPath.extract_ppath_from_first_trx tpath in
       List.fold plst ~init:(cmap', pmap') ~f:(fun (cmap'', pmap'') ppath ->
           let (cands : cand list) = get_cands (cmap', pmap') imap ppath qid in
           update_cmap_and_pmap ctx slvr ppath qid cands (cmap'', pmap'')
       )
   )
(* function precond_search end *)

let pick_refutable_path_f_gen :
    Res.config -> Res.res -> Tz.qid -> Refute.PickFun.t =
   let const_MAX_SCORE = 1000 in
   (* let const_IND_PENALTY = 100 in *)
   let integer_score_of_ind_uind_pair : int -> int * int -> int =
     fun loc_i (ind_count, uind_count) ->
     if ind_count + uind_count = 0
     then (
       try const_MAX_SCORE / Int.pow 2 loc_i with
       | _ -> 0
     )
     else const_MAX_SCORE * uind_count / (ind_count + uind_count)
   in
   let float_score_of_intlist_score : int list -> float =
     fun nl ->
     let len = List.length nl in
     List.foldi nl
       ~init:(float_of_int const_MAX_SCORE /. Float.int_pow 2.0 len)
       ~f:(fun i acc n -> (float_of_int n /. Float.int_pow 2.0 (i + 1)) +. acc)
   in
   (* FUNCTION START *)
   fun cfg res query_id (smt_ctx, smt_slvr) ppaths ->
   let ind_info = res.Res.r_idts in
   let target_qres =
      List.find_exn res.r_qr_lst ~f:(fun qres ->
          Tz.equal_qid qres.qr_qid query_id
      )
   in
   let rec get_score_i : MState.t -> int list =
     fun ms ->
     let mslen = MState.get_length ms in
     if mslen < 1
     then []
     else (
       let v =
          let scoring_target_ss = MState.get_first_ss ms in
          let (start_prec_set : CSet.t) =
             Res.SMYMap.find target_qres.qr_prec_map (MState.get_summary ms)
             |> Option.value ~default:CSet.empty
          in
          let (block_prec_set : CSet.t) =
             Res.SMYMap.find target_qres.qr_prec_map (MState.get_summary ms)
             |> Option.value ~default:CSet.empty
          in
          (* let (start_prec_set : CSet.t) =
                Inv.find_ordered_cand ~remove_unflaged:true
                  ~remove_not_precond:true res.r_cands
                  scoring_target_ss.ss_start_mci query_id
                |> CSet.of_list
             in *)
          (* let (block_prec_set : CSet.t) =
                Inv.find_ordered_cand ~remove_unflaged:true
                  ~remove_not_precond:true res.r_cands
                  scoring_target_ss.ss_block_mci query_id
                |> CSet.of_list
             in *)
          let (inductive_count_tot, un_inductive_count_tot) =
             Inv.count_each_cands ind_info scoring_target_ss
               (start_prec_set, block_prec_set)
          in
          integer_score_of_ind_uind_pair (mslen - 1)
            (inductive_count_tot, un_inductive_count_tot)
       in
       v :: get_score_i (MState.get_tail_ms ms)
     )
   in
   let update_score : Res.PPath.t -> Res.PPath.t =
     fun ppath ->
     if not (List.length ppath.pp_score < MState.get_length ppath.pp_mstate - 1)
     then ppath
     else
       {
         ppath with
         pp_score = get_score_i (MState.get_tail_ms ppath.pp_mstate);
       }
   in
   (* 1. update ppaths' score (for newly created paths) *)
   let score_updated_ppaths = PPSet.map ppaths ~f:update_score in
   (* 2. sort paths by their score, for each rmci *)
   let rmci_accumulated_map =
      let open Refute in
      PPSet.fold score_updated_ppaths ~init:Refute.RMCIMap.empty
        ~f:(fun accmap ppath ->
          let start_rmci =
             (MState.get_first_ss ppath.pp_mstate).ss_start_mci
             |> TzUtil.get_reduced_mci
          in
          Refute.RMCIMap.update accmap start_rmci ~f:(function
          | None   -> [ ppath ]
          | Some l -> ppath :: l
          )
      )
   in
   let sorted_rmci_accumulated_map =
      let open Refute in
      let open Res in
      let compare : PPath.t -> PPath.t -> int =
        fun pp1 pp2 ->
        -1
        * compare_float
            (float_score_of_intlist_score pp1.pp_score)
            (float_score_of_intlist_score pp2.pp_score)
      in
      RMCIMap.map rmci_accumulated_map ~f:(List.sort ~compare)
   in
   (* 3. pick N SAT paths for each rmci *)
   let rec take_N_SAT_paths :
       Res.PPath.t list ->
       int ->
       Res.PPath.t list ->
       Res.PPath.t list * Res.PPath.t list =
     fun acc_take_l n pathl ->
     match (pathl, n) with
     | (_, n) when n <= 0 -> (acc_take_l, pathl)
     | ([], _) -> (acc_take_l, pathl)
     | (p :: tl, _) -> (
       let (filled_p, _) =
          Res.PPath.satisfiability_fill (smt_ctx, smt_slvr) p
       in
       match filled_p with
       | { pp_satisfiability = Some Smt.Solver.SAT; _ } ->
         take_N_SAT_paths (filled_p :: acc_take_l) (n - 1) tl
       | _ -> take_N_SAT_paths acc_take_l n tl
     )
   in
   Refute.RMCIMap.fold sorted_rmci_accumulated_map ~init:([], [])
     ~f:(fun ~key:_ ~data:lst (acc_sl, acc_nl) ->
       take_N_SAT_paths [] cfg.cfg_ppath_k lst
       |> (fun (sl, nl) -> (sl @ acc_sl, nl @ acc_nl))
   )
   |> (fun (sl, nl) -> (Res.PPSet.of_list sl, Res.PPSet.of_list nl))
(* function pick_refutable_path_f_gen end *)

(******************************************************************************)
(******************************************************************************)
(* Synergetic Run                                                             *)
(******************************************************************************)
(******************************************************************************)

(* Query Result ***************************************************************)

let syn_run_qres_escape_condition : Res.config -> Res.qres -> bool =
   let open Res in
   fun { cfg_timer; cfg_memory; _ } { qr_prv_flag; qr_rft_flag; _ } ->
   if (* 1. Timeout *)
      Utils.Time.is_timeout cfg_timer
   then true
   else if (* 2. Memoryout *)
           Utils.Memory.is_memoryout cfg_memory
   then true
   else if (* 3. Query result is already judged *)
           equal_prover_flag qr_prv_flag PF_p
           || not (equal_refuter_flag qr_rft_flag RF_u)
   then true
   else false
(* function syn_run_qres_escape_condition end *)

let syn_run_qres_atomic_action :
    Res.config ->
    Inv.inv_map ->
    Inv.cand_map * Res.qres ->
    Inv.cand_map * Res.qres =
   let open Res in
   fun cfg imap (cmap, qres) ->
   if syn_run_qres_escape_condition cfg qres
   then (cmap, qres)
   else (
     let ((updated_cmap : Inv.cand_map), (qr_prec_map : CSet.t SMYMap.t)) =
        precond_search cfg.cfg_ppath_k cfg.cfg_smt_ctxt cfg.cfg_smt_slvr imap
          qres.qr_qid qres.qr_last_picked_paths (cmap, qres.qr_prec_map)
     in
     (updated_cmap, { qres with qr_prec_map })
   )
(* function syn_run_qres_atomic_action end *)

(* Result *********************************************************************)

let syn_run_res_atomic_action : Res.config -> Res.res -> Res.res =
   let open Res in
   fun cfg res ->
   let ((updated_cmap : Inv.cand_map), (r_qr_lst : qres list)) =
      List.fold_right res.r_qr_lst
        ~f:(fun qres (cmap, qrlst) ->
          let ((updated_cmap : Inv.cand_map), (updated_qres : qres)) =
             syn_run_qres_atomic_action cfg res.r_inv (cmap, qres)
          in
          (updated_cmap, updated_qres :: qrlst))
        ~init:(res.r_cands, [])
   in
   let (r_cands : Inv.cand_map) =
      let open Inv in
      let (live_q : QIDSet.t) =
         List.fold r_qr_lst ~init:QIDSet.empty
           ~f:(fun acc { qr_qid; qr_prv_flag; _ } ->
             if equal_prover_flag qr_prv_flag PF_u
             then QIDSet.add acc qr_qid
             else acc
         )
      in
      RMCIMap.map updated_cmap ~f:(fun data ->
          CMap.map data ~f:(fun (flag, qmap) ->
              if QIDMap.existsi qmap ~f:(fun ~key ~data ->
                     QIDSet.mem live_q key && snd data = 0
                 )
              then (flag, qmap)
              else (false, qmap)
          )
      )
   in
   { res with r_qr_lst; r_cands }
(* function syn_run_res_atomic_action end *)

(* Entry Point ****************************************************************)

let syn_run_escape_condition : Res.config -> Res.res -> bool =
   let open Res in
   fun { cfg_timer; cfg_memory; _ } _ ->
   if (* 1. Timeout *)
      Utils.Time.is_timeout cfg_timer
   then (
     Utils.Log.debug (fun m -> m "Coop : syn_run_escape_condition : TIMEOUT!!!");
     true
   )
   else if (* 2. Memoryout *)
           Utils.Memory.is_memoryout cfg_memory
   then (
     Utils.Log.debug (fun m ->
         m "Coop : syn_run_escape_condition : MEMORYOUT!!!"
     );
     true
   )
   else false
(* function syn_run_escape_condition end *)
