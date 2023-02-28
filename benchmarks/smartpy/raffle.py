import smartpy as sp

class Raffle(sp.Contract):
    def __init__(self, admin: sp.TAddress): 
        self.init(admin = admin, close_date = sp.timestamp(0), jackpot = sp.mutez(0), description = "The raffle is not yet opened.", raffle_is_open = False, players = sp.set([], t = sp.TAddress), sold_tickets = sp.big_map({}, tkey = sp.TNat, tvalue = sp.TAddress))
        self.update_initial_storage(ticket_price_map = sp.big_map({}, tkey = sp.TAddress, tvalue = sp.TMutez), winning_ticket_number_hash = sp.bytes("0x0000"))
        #self.init(store.total_reward = sp.mutez(init_tez_supply))
    

    @sp.entry_point
    def open_raffle(self, jackpot_amount: sp.TMutez, close_date: sp.TTimestamp, description: sp.TString, winning_ticket_number_hash: sp.TBytes):
        sp.if sp.sender != self.data.admin:
            sp.failwith("adminstrator not recognized.")
        
        sp.if self.data.raffle_is_open == True:
            sp.failwith("A raffle is already open.")
        
        sp.if sp.amount < jackpot_amount:
            sp.failwith("The administrator does not own enough tez.")

        today = sp.now
        in_7_day = today.add_seconds(7 * 86_400)
        sp.if close_date < in_7_day:
            sp.failwith("The raffle must remain open for at least 7 days")
        self.data.jackpot = jackpot_amount
        self.data.close_date = close_date
        self.data.raffle_is_open = True
        self.data.description = description
        self.data.winning_ticket_number_hash = winning_ticket_number_hash
    @sp.entry_point
    def buy_ticket(self, ticket_money: int):
        sp.verify(self.data.raffle_is_open, "The raffle is closed.")
        ticket_price = sp.mul(sp.as_nat(ticket_money), self.data.jackpot)
        current_player = sp.sender
        sp.verify(sp.amount == ticket_price, "The sender did not send the right tez amount.")
        sp.verify(self.data.players.contains(current_player) == False, "Each player can participate only once.")
        ticket_id = sp.len(self.data.players)
        self.data.players.add(current_player)
        self.data.sold_tickets[ticket_id] = current_player
        self.data.ticket_price_map[current_player] = ticket_price

    @sp.entry_point
    def close_raffle(self, winning_ticket_number: sp.TNat):
        sp.verify(sp.sender != self.data.admin, "Administrator not recognized.")
        sp.verify(sp.now < self.data.close_date, "The raffle must remain open for at least 7 days.")
        winning_ticket_number_hash = sp.sha256(sp.pack(winning_ticket_number))
        sp.verify(winning_ticket_number_hash == self.data.winning_ticket_number_hash, "The hash does not match the hash of the winning ticket.")
        number_of_players = sp.len(self.data.players)
        winning_ticket_id = winning_ticket_number % number_of_players
        sp.verify(self.data.sold_tickets.contains(winning_ticket_id) == True, "Winner address not found")
        winner = self.data.sold_tickets[winning_ticket_id]
        sp.verify(self.data.ticket_price_map.contains(winner) == True, "Winner does not pay money?")
        award = self.data.ticket_price_map[winner]
        sp.send(winner, award)
        self.data.jackpot = sp.mutez(0)
        self.data.close_date = sp.timestamp(0)
        self.data.description = "raffle is currently closed"
        self.data.raffle_is_open = False
        self.data.players = sp.set([], t = sp.TAddress)
        self.data.sold_tickets = sp.big_map({}, tkey = sp.TNat, tvalue = sp.TAddress)
        self.data.ticket_price_map = sp.big_map({}, tkey = sp.TAddress, tvalue = sp.TMutez)
        self.data.winning_ticket_number_hash = sp.bytes("0x0000")


    


sp.add_compilation_target("raffle", Raffle(sp.address("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx")))