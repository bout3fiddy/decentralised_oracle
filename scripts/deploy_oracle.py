import datetime
import brownie.network as network
from brownie import accounts, decentralised_oracle
from brownie.network import max_fee, priority_fee


name = "cvxCRV Oracle"
token_ticker = "cvxCRV"
cvxcrv_crv_curve_factory_pool = "0x9D0464996170c6B9e75eED71c68B99dDEDf279e8"
crvusd_chainlink_oracle = "0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f"
crvusd_chainlink_price = 493268481 * 10 ** 10
time_queried_chainlink = 1640810328


def main():
    account = accounts[0]
    oracle = decentralised_oracle.deploy(
        name,
        token_ticker,
        cvxcrv_crv_curve_factory_pool,
        crvusd_chainlink_oracle,
        crvusd_chainlink_price,
        time_queried_chainlink,
        {"from": account},
    )
