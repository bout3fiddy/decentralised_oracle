import brownie
import pytest


def test_deposit_bounty(deployed_oracle, alice, token):

    _amount = 100 * 10 ** token.decimals()
    token.approve(deployed_oracle, _amount, {"from": alice})
    deployed_oracle.deposit_bounty(token.address, _amount, {"from": alice})
    contract_weth_balance = token.balanceOf(deployed_oracle.address)
    assert contract_weth_balance == _amount
    print("contract weth balance: ", contract_weth_balance)


def test_deposit_bounty_wrong_token_address(deployed_oracle, alice, token):

    _amount = 100 * 10 ** token.decimals()
    token.approve(deployed_oracle, _amount, {"from": alice})
    wrong_token_address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc3"
    with brownie.reverts("dev: can only deposit weth"):
        deployed_oracle.deposit_bounty(wrong_token_address, _amount, {"from": alice})
