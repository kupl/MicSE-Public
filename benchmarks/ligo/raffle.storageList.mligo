#include "raffle.mligo"
let initial_storage: storage = {
    admin = ("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx": address);
    close_date = (0: timestamp);
    jackpot = (0tez: tez);
    description = ("The raffle is not yet opened.": string);
    raffle_is_open = false;
    players = (Set.empty: address set);
    sold_tickets = (Big_map.empty: (nat, address) big_map);
    ticket_price_map = (Big_map.empty: (address, tez) big_map);
    winning_ticket_number_hash = 0x0000;
}