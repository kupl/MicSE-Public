
open! Core

let const_SCORE_MAGNIFY_COEF : float = 8.0
(* higher value for higher refute ratio resolution *)

let const_SCORE_TOLERANCE_COEF : float = 0.5
(* 0.0 ~ 1.0, 0.0 is REFTUE-first and 1.0 is LENGTH-first. *)

let gen_common_prec_elim_floatscore :
    Res.config -> Res.res -> Res.qres -> Res.PPath.t -> float =
  fun _ _ _ { pp_score; _ } ->
  if List.length pp_score = 0
  then 0.0
  else (
    let len = List.length pp_score |> float_of_int in
    let r_count : float = List.fold pp_score ~init:0 ~f:( + ) |> float_of_int in
    (((r_count /. len) -. 1.0) *. const_SCORE_MAGNIFY_COEF)
    -. (const_SCORE_TOLERANCE_COEF *. len)
    |> Float.round_down
  )

let gen_common_prec_elim_scorepolicy :
    Res.config -> Res.res -> Res.qres -> Res.PPath.t -> int list =
   let rec get_trxpath_tl : MState.t -> MState.t =
      let open MState in
      fun ms ->
      match List.length ms with
      | 0 -> []
      | 1 -> []
      | _ ->
        let tl = get_tail_ms ms in
        if TzUtil.is_trx_entry_state (tl |> get_first_ss)
        then tl
        else get_trxpath_tl tl
   in
   fun _ res qres { pp_mstate; pp_score; _ } ->
   let get_preconds : MState.t -> Inv.CSet.t option = function
   | [] -> None
   | ms -> Res.SMYMap.find qres.qr_prec_map (MState.get_summary ms)
   in
   let strengthen_preconds_using_invariant :
       MState.t -> Inv.CSet.t option -> Inv.CSet.t option =
      let open Inv in
      fun mstate ->
      if List.is_empty mstate
      then (fun _ -> None)
      else
        fun preconds_opt ->
        let rmci : Tz.r_mich_cut_info =
           (MState.get_first_ss mstate).ss_start_mci |> TzUtil.get_reduced_mci
        in
        let cur_inv : cand = find_inv_by_rmci res.r_inv rmci in
        let inv_strengthened_preconds =
           Option.map preconds_opt
             ~f:(CSet.map ~f:(fun cand -> join_cands cur_inv cand))
        in
        let filtered_strengthened =
           Option.map inv_strengthened_preconds
             ~f:
               (CSet.filter ~f:(fun cand ->
                    mem_by_rmci res.r_cands ~key:rmci ~value:cand
                )
               )
        in
        filtered_strengthened
   in
   let last_score : int =
      let last_path = get_trxpath_tl pp_mstate in
      let last2_path = get_trxpath_tl last_path in
      let last_preconds : Inv.CSet.t option = get_preconds last_path in
      let last2_preconds : Inv.CSet.t option =
         get_preconds last2_path
         |> strengthen_preconds_using_invariant last2_path
      in
      match (last_preconds, last2_preconds) with
      | (Some v1, Some v2) ->
        if Inv.CSet.length v1 < Inv.CSet.length v2 then 1 else 0
      | (Some _, None)     -> 1
      | (None, Some _)     -> 0
      | (None, None)       -> 0
   in
   last_score :: pp_score
