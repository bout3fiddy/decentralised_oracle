import brownie
from brownie import chain
import pytest


def test_update_oracle(deployed_oracle_with_bounty, charlie, token):

    tx = deployed_oracle_with_bounty.update_oracle({"from": charlie})
    initial_oracle_price = tx.return_value
    chain.sleep(3700)
    chain.mine()
    tx = deployed_oracle_with_bounty.update_oracle({"from": charlie})
    oracle_price_post_sleep = tx.return_value
    print(initial_oracle_price, oracle_price_post_sleep)
    assert initial_oracle_price != oracle_price_post_sleep
    assert token.balanceOf(charlie) > 0
