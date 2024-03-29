(* Manage_s : Manager for MicSE-Synergetic *)

exception ManageSError of string

(******************************************************************************)
(******************************************************************************)
(* Common Datatypes                                                           *)
(******************************************************************************)
(******************************************************************************)

(* Set of Tz.mich_f *)
module MFSet : module type of Core.Set.Make (Tz.MichF_cmp)

(******************************************************************************)
(******************************************************************************)
(* Status Printing                                                            *)
(******************************************************************************)
(******************************************************************************)

val print_num_of_cands : Res.config -> Res.res -> unit

val print_size_of_cand_space : Res.res -> unit

val print_picked_paths : Res.res -> unit

val print_expanded_paths : Res.res -> unit

(******************************************************************************)
(******************************************************************************)
(* Entry Point                                                                *)
(******************************************************************************)
(******************************************************************************)

val enhanced_prover_run : Res.config -> Res.res -> Res.res

val syn_run_escape_condition : Res.config -> Res.res -> bool

val syn_run : Res.config -> Res.res -> Res.res
