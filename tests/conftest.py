from brownie.network import contract
import pytest
from brownie_tokens import MintableForkToken


NAME = "cvxCRV Oracle"
TOKEN_TICKER = "cvxCRV"
CVXCRV_F_POOL = "0x9D0464996170c6B9e75eED71c68B99dDEDf279e8"
CRVUSD_CHAINLINK_ORACLE = "0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f"
CRVUSD_INIT_PRICE = 493268481 * 10 ** 10
INIT_PRICE_TIMESTAMP = 1640810328


@pytest.fixture(scope="session")
def alice(accounts):
    return accounts[0]


@pytest.fixture(scope="session")
def charlie(accounts):
    return accounts[1]


@pytest.fixture(scope="module")
def deployed_oracle(decentralised_oracle, alice):
    yield decentralised_oracle.deploy(
        NAME,
        TOKEN_TICKER,
        CVXCRV_F_POOL,
        CRVUSD_CHAINLINK_ORACLE,
        CRVUSD_INIT_PRICE,
        INIT_PRICE_TIMESTAMP,
        {"from": alice},
    )


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    pass
