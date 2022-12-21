type openRaffleParameter is tez * timestamp * option(string) * bytes
type buyTicketParameter is unit
type closeRaffleParameter is nat
type raffleEntrypoints is 
| OpenRaffle of openRaffleParameter
| BuyTicket of buyTicketParameter
| CloseRaffle of closeRaffleParameter

type storage is record [
    admin : address;
    close_date : timestamp;
    jackpot : tez;
    description : string;
    raffle_is_open : bool;
    players : set (address);
    sold_tickets : big_map (nat, address);
    winning_ticket_number_hash : bytes;
]

type returnType is list (operation) * storage

function div (const a : nat; const b : nat) : option (nat) is
    if b = 0n then None else Some(a/b)

function open_raffle (const jackpot_amount : tez; const close_date : timestamp; const description : option(string); const winning_ticket_number_hash: bytes; var store : storage) : returnType is {
    if Tezos.get_source() =/= store.admin
    then failwith ("administrator not recognized.")
    else {
        if not store.raffle_is_open then {
            if Tezos.get_amount() < jackpot_amount
            then failwith ("The administrator does not own enough tez.")
            else {
                const today : timestamp = Tezos.get_now();
                const seven_day : int = 7  * 86400;
                const in_7_day : timestamp = today + seven_day;
                const is_close_date_not_valid: bool = close_date < in_7_day;
                if is_close_date_not_valid
                then failwith ("The raffle must remain open for at least 7 days.")
                else {
                    patch store with record [
                        jackpot = jackpot_amount;
                        close_date = close_date;
                        raffle_is_open = True;
                        winning_ticket_number_hash = winning_ticket_number_hash; // the hash is saved into the storage
                    ];

                    case description of [
                    | Some(d) -> patch store with record [description=d]
                    | None -> {skip}
                    ]
                }
            }
        } 
        else {
            failwith ("A raffle is already open.")
        }
    }
} with ((nil: list(operation)), store)

function buy_ticket (const _param: unit; var store: storage): returnType is {
    if store.raffle_is_open then {
        const ticket_price : tez = 1tez;
        const current_player : address = Tezos.get_sender();
        if Tezos.get_amount() =/= ticket_price
        then failwith("The sender did not send the right tez amount.")
        else {
            if store.players contains current_player
            then failwith("Each player can participate only once.")
            else {
                const ticket_id : nat = Set.size(store.players);
                store.players := Set.add(current_player, store.players);
                store.sold_tickets[ticket_id] := current_player;
            }
        }
    } else {
        failwith("The raffle is closed.")
    }
} with ((nil: list(operation)), store)

function close_raffle (const winning_ticket_number: nat; var store: storage): returnType is { 
    var operations: list(operation) := nil;
    if Tezos.get_source() =/= store.admin then failwith("Administrator not recognized.")
    else {
        if store.raffle_is_open then {
            if Tezos.get_now() < store.close_date then failwith("The raffle must remain open for at least 7 days.")
            else {
                const winning_ticket_number_bytes : bytes = Bytes.pack(winning_ticket_number);
                const winning_ticket_number_hash : bytes = Crypto.sha256(winning_ticket_number_bytes);
                if winning_ticket_number_hash =/= store.winning_ticket_number_hash
                then failwith("The hash does not match the hash of the winning ticket.")
                else {
                    const number_of_players : nat = Set.size(store.players);
                    const winning_ticket_id : nat = winning_ticket_number mod number_of_players;

                    const winner: address =
                        case (store.sold_tickets[winning_ticket_id]) of [
                        | Some(a) -> a
                        | None -> (failwith("Winner address not found"): address)
                        ];
                    
                    const receiver: contract (unit) =
                        case (Tezos.get_contract_opt (winner): option (contract (unit))) of [
                        | Some (c) -> c
                        | None -> (failwith("Winner contract not found."): contract (unit))
                        ];
                    
                    const op: operation = Tezos.transaction(unit, store.jackpot, receiver);
                    operations := list [ op; ];

                    patch store with record [
                        jackpot = 0tez;
                        close_date = (0 : timestamp);
                        description = ("raffle is currently closed" : string);
                        raffle_is_open = False;
                        players = (set[] : set(address));
                        sold_tickets = (big_map[] : big_map (nat, address));
                    ];
                }
            }
        } else {
            failwith("The raffle is closed.")
        }
    }
} with (operations, store)

function main (const action : raffleEntrypoints; const store : storage): list (operation) * storage is
    case action of [
        | OpenRaffle (param) -> open_raffle (param.0, param.1, param.2, param.3, store)
        | BuyTicket (param) -> buy_ticket (param, store)
        | CloseRaffle (param) -> close_raffle (param, store)
    ]