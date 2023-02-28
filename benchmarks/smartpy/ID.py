import smartpy as sp

class ID(sp.Contract):
    def __init__(self, next_id: sp.TInt, name_price: sp.TMutez, skip_price: sp.TMutez): 
        self.init(storage = sp.record(identities = sp.big_map(l = {}, tkey = sp.TInt, tvalue = sp.TRecord(owner = sp.TAddress, controller = sp.TAddress, profile = sp.TBytes)), next_id = next_id, name_price = name_price, skip_price = skip_price))

    
    @sp.entry_point
    def buy(self, profile_: sp.TAddress, initial_controller_: sp.TAddress, price: sp.TMutez):
        sp.if self.data.storage.name_price != sp.amount:
            sp.failwith("Incorrect amount paid.")

        new_id_details = sp.record(owner = sp.sender, controller = initial_controller_, profile = profile_)
        self.data.storage.identities[self.data.storage.next_id] = new_id_details
        self.data.storage.name_price += price

    
    @sp.entry_point
    def update_owner(self, id: sp.TInt, new_owner: sp.TAddress):
        sp.if sp.amount != sp.mutez(0):
            sp.failwith("Updating owner doesn't cost anything.")
        id_identities = self.data.storage.identities[id]
        sp.if id_identities.owner != sp.sender:
            sp.failwith("You are not the owner of this ID.")
        ## 이 부분은 레퍼런스에 없는거 찍은거
        id_identities.owner = new_owner
        self.data.storage.identities = sp.update_map(self.data.storage.identities, id, sp.some(id_identities))


    
    @sp.entry_point
    def update_details(self, id: sp.TInt, new_profile: sp.TBytes, new_controller: sp.TAddress):
        sp.if sp.amount != sp.mutez(0):
            sp.failwith("Updating owner doesn't cost anything.")
        id_identities = self.data.storage.identities[id]
        sp.if id_identities.owner != sp.sender:
            sp.failwith("You are not the owner of this ID.")
        ## 이 부분은 레퍼런스에 없는거 찍은거
        id_identities.profile = new_profile
        id_identities.controller = new_controller
        self.data.storage.identities = sp.update_map(self.data.storage.identities, id, sp.some(id_identities))

    
    @sp.entry_point
    def skip(self, skip_tez: sp.TMutez):
        sp.if sp.amount != self.data.storage.skip_price:
            sp.failwith("Incorrect amount paid.")

        (quotient, remainder) = sp.match_pair(sp.ediv(self.data.storage.skip_price + skip_tez, sp.mutez(1000000)).open_some())
        self.data.storage.skip_price = remainder



sp.add_compilation_target("id", ID(sp.int(100), sp.mutez(100), sp.mutez(100)))