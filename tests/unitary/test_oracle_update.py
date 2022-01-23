import brownie
import pytest


def test_update_oracle(deployed_oracle, charlie):

    initial_oracle_price = deployed_oracle.latestAnswer()

    tx = deployed_oracle.update_ema_rate({"from": charlie})
    oracle_price_post_update = deployed_oracle.latestAnswer()

    assert initial_oracle_price != oracle_price_post_update
