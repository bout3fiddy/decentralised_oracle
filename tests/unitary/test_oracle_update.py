import brownie
from brownie import chain
import pytest


def test_chainlink_price(deployed_oracle, charlie):

    tx = deployed_oracle.get_chainlink_price({"from": charlie})
    chainlink_price = tx.return_value
    print(f"chainlink price: {chainlink_price}")
    assert chainlink_price > 0


def test_update_oracle(deployed_oracle_with_bounty, charlie, token):

    chain.snapshot()
    current_block = brownie.web3.eth.get_block_number()
    print(f"timestamp: {chain.time()}")

    filled_indices = deployed_oracle_with_bounty.filled_indices()
    print(f"filled indices: {filled_indices}")
    last_swap_rate = deployed_oracle_with_bounty.last_swap_rate()
    print(f"last_swap_rate: {last_swap_rate}")
    average_swap_rate = deployed_oracle_with_bounty.average_swap_rate()
    print(f"average_swap_rate: {average_swap_rate}")

    tx = deployed_oracle_with_bounty.update_oracle(
        {"from": charlie}, block_identifier=chain.height
    )
    initial_oracle_price = tx.return_value

    filled_indices = deployed_oracle_with_bounty.filled_indices()
    print(f"filled indices: {filled_indices}")
    last_swap_rate = deployed_oracle_with_bounty.last_swap_rate()
    print(f"last_swap_rate: {last_swap_rate}")
    average_swap_rate = deployed_oracle_with_bounty.average_swap_rate()
    print(f"average_swap_rate: {average_swap_rate}")

    chain.mine(timedelta=60 * 60)

    tx = deployed_oracle_with_bounty.update_oracle({"from": charlie})
    oracle_price_post_sleep = tx.return_value

    print("initial oracle price: ", initial_oracle_price)
    print("oracle price post sleep:", oracle_price_post_sleep)

    assert initial_oracle_price != oracle_price_post_sleep
    assert token.balanceOf(charlie) > 0

    chain.revert()
