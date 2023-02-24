#include "raffle.ligo"
const initial_storage: storage = record [
    admin = ("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx": address);
    close_date = (0: timestamp);
    jackpot = 0tez;
    description = ("raffle is currently closed" : string);
    raffle_is_open = False;
    players = (set[] : set(address));
    sold_tickets = (big_map[] : big_map (nat, address));
    ticket_price_map = (big_map[] : big_map (address, tez));
    winning_ticket_number_hash = (0x0000: bytes);
]
