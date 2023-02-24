type buy_taco_parameter = nat

type taco_shop_entrypoint = 
| Buy_taco of buy_taco_parameter


type taco_supply = {
    current_stock : nat ;
    max_price     : tez
}


type taco_shop_storage = (nat, taco_supply) map 

type return = operation list * taco_shop_storage

let ownerAddress : address = ("tz1TGu6TN5GSez2ndXXeDX6LgUDvLzPLqgYV" : address)

let donationAddress : address = ("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx" : address)


let buy_taco (taco_kind_index, taco_shop_storage : buy_taco_parameter * taco_shop_storage) : return = 
    // Retrieve the taco_kind from the contract's storage or fail
    let taco_kind : taco_supply =
        match Map.find_opt taco_kind_index taco_shop_storage with
        Some (kind) -> kind
        | None -> (failwith ("Unknown kind of taco.") : taco_supply)
    in

    let current_purchase_price : tez =
        taco_kind.max_price / taco_kind.current_stock in

    // We won't sell tacos if the amount is not correct
    let () = 
        assert_with_error ((Tezos.get_amount ()) >= current_purchase_price) 
        "Sorry, the taco you are trying to purchase has a different price" in

    // Decrease the stock by 1n, because we have just sold one
    let taco_kind = { taco_kind with current_stock = (abs (taco_kind.current_stock - 1n)) } in

    // Update the storage with the refreshed taco_kind
    let taco_shop_storage = Map.update taco_kind_index (Some taco_kind) taco_shop_storage in

    let receiver : unit contract =
        match (Tezos.get_contract_opt ownerAddress: unit contract option) with
        Some (contract) -> contract
        | None -> (failwith ("Not a contract") : unit contract)
    in

    let donationReceiver : unit contract  =
    match ((Tezos.get_contract_opt donationAddress) : unit contract option) with
        Some contract -> contract
    | None -> ((failwith "Not a contract") : unit contract)
    in
    let donationAmount : tez = (Tezos.get_amount ()) / 10n in
    // Here is query => Is this operation is
    let profit = 9n * donationAmount in

    let operations : operation list = [Tezos.transaction () profit receiver ; Tezos.transaction () donationAmount donationReceiver]
    in

    operations, taco_shop_storage



let main (action, taco_shop_storage : taco_shop_entrypoint * taco_shop_storage) : return =
    match action with
    | Buy_taco param -> buy_taco (param, taco_shop_storage)
