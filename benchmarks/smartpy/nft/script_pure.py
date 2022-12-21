import smartpy as sp
FA2 = sp.io.import_script_from_url("https://smartpy.io/templates/fa2_lib.py")

@sp.add_test(name="Simplest NFT")
def test():
    sc = sp.test_scenario()
    c1 = FA2.Fa2Nft(
        metadata = sp.utils.metadata_of_url("https://example.com"),
    )
    sc += c1
