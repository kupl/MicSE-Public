(* Coop : Cooperation model for MicSE-Synergetic *)

exception CoopError of string

(******************************************************************************)
(******************************************************************************)
(* Common Datatypes                                                           *)
(******************************************************************************)
(******************************************************************************)

(* Set of Tz.qid *)
module QIDSet : module type of Core.Set.Make (Lib.Tz.QId_cmp)

(* Set of Res.PPath.t *)
module PPSet : module type of Core.Set.Make (Lib.Res.PPath)

(* Set of Inv.cand *)
module CSet : module type of Core.Set.Make (Lib.Inv.Cand_cmp)

(* Map of MState.summary *)
module SMYMap : module type of Core.Map.Make (Lib.MState.SMY_cmp)

(******************************************************************************)
(******************************************************************************)
(* Cooperation                                                                *)
(******************************************************************************)
(******************************************************************************)

val precond_search :
  int ->
  Lib.Smt.Ctx.t ->
  Lib.Smt.Solver.t ->
  Lib.Inv.inv_map ->
  Lib.Tz.qid ->
  PPSet.t ->
  Lib.Inv.cand_map * CSet.t SMYMap.t ->
  Lib.Inv.cand_map * CSet.t SMYMap.t

val pick_refutable_path_f_gen :
  Lib.Res.config -> Lib.Res.res -> Lib.Tz.qid -> Lib.Refute.PickFun.t

(******************************************************************************)
(******************************************************************************)
(* Synergetic Run                                                             *)
(******************************************************************************)
(******************************************************************************)

(* Query Result ***************************************************************)

val syn_run_qres_escape_condition : Lib.Res.config -> Lib.Res.qres -> bool

val syn_run_qres_atomic_action :
  Lib.Res.config ->
  Lib.Inv.inv_map ->
  Lib.Inv.cand_map * Lib.Res.qres ->
  Lib.Inv.cand_map * Lib.Res.qres

(* Result *********************************************************************)

val syn_run_res_atomic_action : Lib.Res.config -> Lib.Res.res -> Lib.Res.res

(* Entry Point ****************************************************************)

val syn_run_escape_condition : Lib.Res.config -> Lib.Res.res -> bool
