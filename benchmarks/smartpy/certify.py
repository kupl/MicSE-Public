import smartpy as sp

class Certification(sp.Contract):
    def __init__(self):
        self.init(certified=[])

    @sp.entry_point
    def certify(self, params):
        self.data.certified.push(params)

@sp.add_test(name = "Certify")
def test():
    contract= Certification()
    scenario = sp.test_scenario()

    scenario+=contract
    scenario+=contract.certify("Anil Oener")
    scenario+=contract.certify("Ibo Sy")
