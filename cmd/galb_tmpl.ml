(******************************************************************************)
(* TEMPLATES                                                                  *)
(******************************************************************************)

let create_deposit = [| 26; 30; 35; 39; 48; 52; 57; 61 |]

let process_reward_start = [| 83; 85 |]

let process_reward_outer_loop_start = [| 88 |]

let process_reward_inner_loop =
   [| 111; 112; 121; 122; 134; 135; 144; 145; 157; 158; 167; 168 |]

let process_reward_outer_loop_end = [| 169 |]

let process_reward_end = [| 172; 173 |]

let remove_deposit = [| 188; 190; 195; 197; 209; 211; 216; 218 |]

let set_backend = [| 219 |]

let set_delegate_node = [| 221 |]

let set_operator = [| 224 |]

let set_owner = [| 226 |]

let set_start_cycle_increment_value = [| 228 |]

let set_team_fee_percent = [| 230 |]

let set_teamfee_account = [| 233 |]

let set_tradein_account = [| 235 |]

let set_tradein_fee_percent = [| 237 |]

let setup_reward_start = [| 241 |]

let setup_reward_loop = [| 246; 247 |]

let setup_reward_end = [| 251; 252 |]

let withdraw = [| 268; 281 |]

let withdraw_team_fee = [| 285 |]

let querytpl_606_24 =
   [|
     create_deposit;
     set_backend;
     process_reward_start;
     process_reward_outer_loop_start;
     process_reward_inner_loop;
     process_reward_outer_loop_end;
     process_reward_end;
     setup_reward_start;
     setup_reward_loop;
     setup_reward_end;
     process_reward_start;
     process_reward_outer_loop_start;
     process_reward_inner_loop;
     process_reward_outer_loop_end;
     process_reward_end;
     withdraw_team_fee;
   |]

let querytpl_1076_42 =
   [|
     create_deposit;
     withdraw;
     create_deposit;
     set_backend;
     process_reward_start;
     process_reward_outer_loop_start;
     process_reward_inner_loop;
   |]

let querytpl_1134_42 =
   [|
     create_deposit;
     process_reward_start;
     process_reward_outer_loop_start;
     process_reward_inner_loop;
     process_reward_outer_loop_end;
     process_reward_end;
     setup_reward_start;
     setup_reward_loop;
     setup_reward_end;
     process_reward_start;
     process_reward_outer_loop_start;
   |]

let querytpl_1222_42 =
   [|
     create_deposit;
     create_deposit;
     setup_reward_start;
     setup_reward_loop;
     setup_reward_loop;
     setup_reward_end;
     process_reward_start;
     process_reward_outer_loop_start;
     process_reward_inner_loop;
   |]

let querytpl_1286_42 =
   [|
     set_tradein_fee_percent;
     create_deposit;
     create_deposit;
     set_backend;
     setup_reward_start;
     setup_reward_loop;
     setup_reward_loop;
     setup_reward_end;
     process_reward_start;
     process_reward_outer_loop_start;
     process_reward_inner_loop;
   |]

let querytpl_1320_42 =
   [|
     set_team_fee_percent;
     create_deposit;
     create_deposit;
     set_backend;
     setup_reward_start;
     setup_reward_loop;
     setup_reward_end;
     process_reward_start;
     process_reward_outer_loop_start;
     process_reward_inner_loop;
   |]
