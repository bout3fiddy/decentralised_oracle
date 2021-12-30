import brownie
import pytest


def test_deposit_bounty(decentralised_oracle, alice, token):

    _amount = 100 * 10 ** token.decimals()
    token.approve(decentralised_oracle, _amount, {"from": alice})
    decentralised_oracle.deposit_bounty(token.address, _amount, {"from": alice})
    contract_weth_balance = token.balanceOf(decentralised_oracle.address)
    assert contract_weth_balance == _amount
    print("contract weth balance: ", contract_weth_balance)
