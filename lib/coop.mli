(* Coop : Cooperation model for MicSE-Synergetic *)

exception CoopError of string

(******************************************************************************)
(******************************************************************************)
(* Common Datatypes                                                           *)
(******************************************************************************)
(******************************************************************************)

(* Set of Tz.qid *)
module QIDSet : module type of Core.Set.Make (Tz.QId_cmp)

(* Set of Res.PPath.t *)
module PPSet : module type of Core.Set.Make (Res.PPath)

(* Set of Inv.cand *)
module CSet : module type of Core.Set.Make (Inv.Cand_cmp)

(* Map of MState.summary *)
module SMYMap : module type of Core.Map.Make (MState.SMY_cmp)

(******************************************************************************)
(******************************************************************************)
(* Cooperation                                                                *)
(******************************************************************************)
(******************************************************************************)

val precond_search :
  int ->
  Smt.Ctx.t ->
  Smt.Solver.t ->
  Inv.inv_map ->
  Tz.qid ->
  PPSet.t ->
  Inv.cand_map * CSet.t SMYMap.t ->
  Inv.cand_map * CSet.t SMYMap.t

val pick_refutable_path_f_gen :
  Res.config -> Res.res -> Tz.qid -> Refute.PickFun.t

(******************************************************************************)
(******************************************************************************)
(* Synergetic Run                                                             *)
(******************************************************************************)
(******************************************************************************)

(* Query Result ***************************************************************)

val syn_run_qres_escape_condition : Res.config -> Res.qres -> bool

val syn_run_qres_atomic_action :
  Res.config ->
  Inv.inv_map ->
  Inv.cand_map * Res.qres ->
  Inv.cand_map * Res.qres

(* Result *********************************************************************)

val syn_run_res_atomic_action : Res.config -> Res.res -> Res.res

(* Entry Point ****************************************************************)

val syn_run_escape_condition : Res.config -> Res.res -> bool
