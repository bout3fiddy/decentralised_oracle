import brownie
import pytest


def test_update_ema_oracle(ema_rate_oracle, charlie):

    initial_oracle_price = ema_rate_oracle.latestAnswer()

    tx = ema_rate_oracle.update_ema_rate({"from": charlie})
    oracle_price_post_update = ema_rate_oracle.latestAnswer()

    assert initial_oracle_price != oracle_price_post_update


def test_update_ema_windowed_oracle(ema_rate_oracle, charlie):

    initial_oracle_price = ema_rate_oracle.latestAnswer()

    tx = ema_rate_oracle.update_ema_rate({"from": charlie})
    oracle_price_post_update = ema_rate_oracle.latestAnswer()

    assert initial_oracle_price != oracle_price_post_update
