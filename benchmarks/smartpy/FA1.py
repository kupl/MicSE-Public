import smartpy as sp

class FA1(sp.Contract):
    # 초기 저장소
    # 빈 big_map (address, tez)
    # total supply : tez
    def __init__(self, init_tez_supply): 
        self.init(ledger = sp.map(l = {}, tkey = sp.TAddress, tvalue = sp.TMutez))
        self.update_initial_storage(total_supply = sp.mutez(init_tez_supply))
    
    @sp.entry_point
    def transfer(self, from_: sp.TAddress, to_: sp.TAddress, value: sp.TMutez):
        sp.if self.data.ledger[from_] < value:
            sp.failwith("from amount must be bigger or equal with value")
        (quotient1, remainder1) = sp.match_pair(sp.ediv(self.data.ledger[from_], sp.mutez(1)).open_some())
        (quotient2, remainder2) = sp.match_pair(sp.ediv(value, sp.mutez(1)).open_some())
        self.data.ledger[from_] = sp.mul(abs((quotient1 - quotient2)), sp.mutez(1))
        self.data.ledger[to_] += value
    


sp.add_compilation_target("FA1", FA1(3))