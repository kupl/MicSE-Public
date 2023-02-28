import smartpy as sp

class Hashchall(sp.Contract):
    def __init__(self, init_tez_supply): 
        self.init(commits = sp.map(l = {}, tkey = sp.TAddress, tvalue = sp.TRecord(reward = sp.TMutez, salted_hash = sp.TBytes)))
        self.update_initial_storage(total_reward = sp.mutez(init_tez_supply))
    

    @sp.entry_point
    def commit(self, reward_: sp.TMutez, salted_hash_: sp.TBytes):
        c = sp.record(reward = reward_, salted_hash = salted_hash_)
        self.data.commits = sp.update_map(self.data.commits, sp.sender, sp.some(c))


    
    @sp.entry_point
    def reveal(self, chall_owner: sp.TAddress, hashable: sp.TBytes):
        sp.if self.data.commits[chall_owner].salted_hash == sp.sha256(hashable + sp.pack(chall_owner)):
            self.data.total_reward +=  self.data.commits[chall_owner].reward
        
            

sp.add_compilation_target("hashchall", Hashchall(42))