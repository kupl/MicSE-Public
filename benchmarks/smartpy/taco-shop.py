import smartpy as sp

class Taco_shop(sp.Contract):
    def __init__(self):
        self.init(taco_shop_storage  = sp.map(l = {sp.nat(1 ) : sp.record(current_stock = sp.nat(50), max_price = sp.tez(50)), sp.nat(2) : sp.record(current_stock = sp.nat(20), max_price = sp.tez(75)) }, tkey = sp.TNat, tvalue = sp.TRecord(current_stock = sp.TNat, max_price = sp.TMutez))
)
    

    @sp.entry_point
    def buy_taco(self, taco_kind_index: sp.TNat):
        sp.verify(self.data.taco_shop_storage.contains(taco_kind_index), "Unknown kind of taco.")
        taco_kind = self.data.taco_shop_storage[taco_kind_index]
        (quotient, remainder) = sp.match_pair(sp.ediv(taco_kind.max_price, taco_kind.current_stock).open_some())
        current_purchase_price = quotient
        sp.verify(sp.amount >= current_purchase_price, "Sorry, the taco you are trying to purchase has a different price")
        taco_kind.current_stock = sp.as_nat(taco_kind.current_stock - 1)
        self.data.taco_shop_storage[taco_kind_index] = taco_kind
        owner_address = sp.address("tz1TGu6TN5GSez2ndXXeDX6LgUDvLzPLqgYV")
        donation_address = sp.address("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx")
        (donation_amount, remainder) = sp.match_pair(sp.ediv(sp.amount, sp.nat(10)).open_some())
        profit = sp.mul(sp.nat(9), donation_amount)
        sp.send(owner_address, profit)
        sp.send(donation_address, donation_amount)

sp.add_compilation_target("taco_shop", Taco_shop())