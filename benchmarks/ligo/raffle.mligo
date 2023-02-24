type open_raffle_parameter = {
    jackpot_amount: tez;
    close_date: timestamp;
    description: string option;
    winning_ticket_number_hash: bytes;
}
type buy_ticket_parameter = nat
type close_raffle_parameter = nat

type raffleEntrypoints =
| Open_raffle of open_raffle_parameter
| Buy_ticket of buy_ticket_parameter
| Close_raffle of close_raffle_parameter

type storage = {
    admin: address;
    close_date: timestamp;
    jackpot: tez;
    description: string;
    raffle_is_open: bool;
    // 각각의 플레이어들의 주소 집합, 참가자 인원수 제한이 없으므로 맵은 big_map
    players: address set;
    sold_tickets: (nat, address) big_map;
    ticket_price_map: (address, tez) big_map;
    winning_ticket_number_hash: bytes;
}

let div (a, b: nat * nat): nat option =
    if b = 0n then None else Some (a/b)

let open_raffle (parameter, storage: open_raffle_parameter * storage) = 
    let _void: unit =
        if Tezos.get_sender () = storage.admin
        then ()
        else (failwith "administrator not recognized.": unit)
    in
    let _is_open: bool =
        if storage.raffle_is_open
        then (failwith "A raffle is already open.": bool) 
        else false
    in
    let _enough_money: bool =
        if Tezos.get_amount () < parameter.jackpot_amount
        then (failwith "The administrator does not own enough tez.": bool)
        else true
    in
    let today: timestamp = Tezos.get_now ()
    in
    let seven_day: int = 7 * 86_400 in
    let in_7_day: timestamp = today + seven_day in
    let _is_close_date_not_valid: bool =
        if parameter.close_date < in_7_day
        then (failwith "The raffle must remain open for at least 7 days": bool)
        else false 
    in
    let new_storage: storage = {
        storage with
        jackpot = parameter.jackpot_amount;
        close_date = parameter.close_date;
        raffle_is_open = true;
        winning_ticket_number_hash = parameter.winning_ticket_number_hash;
    }
    in
    let new_storage: storage =
        match parameter.description with
        | Some desc -> {new_storage with description = desc}
        | None -> new_storage
    in
    ([]: operation list), new_storage

// make parameter, ticket -> price, (current_player, ticket_price)
let buy_ticket (parameter, storage: buy_ticket_parameter * storage) =
    let _is_open: bool =
        if storage.raffle_is_open
        then true
        else (failwith "The raffle is closed.": bool)
    in
    let ticket_price: tez = parameter * storage.jackpot in
    let current_player: address = Tezos.get_sender () in
    let _is_right_tez_amoount: unit =
        if Tezos.get_amount () <> ticket_price
        then (failwith "The sender did not send the right tez amount.": unit)
        else ()
    in
    let _is_player_once =
        if Set.mem current_player storage.players
        then (failwith "Each player can participate only once.")
        else true
    in
    let ticket_id: nat = Set.size storage.players in
    let new_storage = {
        storage with
        players = Set.add current_player storage.players;
        sold_tickets = Big_map.update ticket_id (Some (current_player)) storage.sold_tickets;
        ticket_price_map = Big_map.update current_player (Some (ticket_price)) storage.ticket_price_map;
    }
    in
    ([]: operation list), new_storage

// when determine reward, if jackpot is succeedd -> 걸었돈 돈을 곱해서 넣어주면 될 듯 하댜
let close_raffle (parameter, storage: close_raffle_parameter * storage) =
    let winning_ticket_number = parameter in
    let _is_admin: bool =
        if Tezos.get_sender () = storage.admin
        then true
        else (failwith "Administrator not recognized.": bool)
    in
    let _is_time_over: bool =
        if Tezos.get_now () < storage.close_date
        then (failwith "The raffle must remain open for at least 7 days.": bool)
        else true
    in
    let winning_ticket_number_bytes: bytes = Bytes.pack winning_ticket_number in
    let winning_ticket_number_hash: bytes = Crypto.sha256 winning_ticket_number_bytes in
    let _is_number_right: bool =
        if winning_ticket_number_hash = storage.winning_ticket_number_hash
        then true
        else (failwith "The hash does not match the hash of the winning ticket.": bool)
    in
    let number_of_players: nat = Set.size storage.players in
    let winning_ticket_id: nat = winning_ticket_number mod number_of_players in
    let winner: address =
        match Big_map.find_opt winning_ticket_id storage.sold_tickets with
        | Some (addr) -> addr
        | None -> (failwith "Winner address not found": address)
    in
    let award: tez =
        match Big_map.find_opt winner storage.ticket_price_map with
        | Some (price) -> price
        | None -> (failwith "Winner does not pay money?": tez)
    in
    let receiver : (unit) contract =
        match Tezos.get_contract_opt (winner) with
        | Some cont -> cont
        | None -> (failwith "Winner contract not found.": (unit) contract)
    in
    let reward_operation: operation = Tezos.transaction () award receiver in
    let new_storage: storage = {
        storage with
        jackpot = 0tez;
        close_date = (0: timestamp);
        description = ("raffle is currently closed": string);
        raffle_is_open = false;
        players = (Set.empty: address set);
        sold_tickets = (Big_map.empty: (nat, address) big_map);
        ticket_price_map = (Big_map.empty: (address, tez) big_map);
    }
    in
    ([reward_operation]: operation list), new_storage

let main (action, storage: raffleEntrypoints * storage): operation list * storage =
    match action with
    | Open_raffle param -> open_raffle (param, storage)
    | Buy_ticket param -> buy_ticket (param, storage)
    | Close_raffle param -> close_raffle (param, storage)