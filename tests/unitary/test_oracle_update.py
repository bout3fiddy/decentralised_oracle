import brownie
import pytest


def test_update_oracle(deployed_oracle, charlie):

    initial_oracle_price = deployed_oracle.latest_oracle_price()

    tx = deployed_oracle.update_oracle({"from": charlie})
    oracle_price_post_update = deployed_oracle.latest_oracle_price()

    assert initial_oracle_price != oracle_price_post_update
