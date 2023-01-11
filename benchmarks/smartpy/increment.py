import smartpy as sp

class Increment(sp.Contract):
    def __init__(self, init_tez_amount):
        self.init(store = sp.mutez(init_tez_amount))

    # Define has_entry_point
    @sp.entry_point
    def increment(self, params):
        self.data.store += params

    @sp.entry_point
    def decrement(self, params):
        operand1= sp.fst(sp.ediv(self.data.store, sp.mutez(1)).open_some())
        operand2 = sp.fst(sp.ediv(params, sp.mutez(1)).open_some())
        print(operand1, operand2)
        result_int = operand1 - operand2
        self.data.store = sp.mul(abs(result_int), sp.mutez(1))

sp.add_compilation_target("increment", Increment(45))