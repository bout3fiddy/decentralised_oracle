from brownie.network import contract
import pytest
from brownie_tokens import MintableForkToken


cvxCRV_POOL_ADDRESS = "0x9D0464996170c6B9e75eED71c68B99dDEDf279e8"
CRVUSD_CHAINLINK_ORACLE = "0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f"


@pytest.fixture(scope="session")
def alice(accounts):
    return accounts[0]


@pytest.fixture(scope="session")
def charlie(accounts):
    return accounts[1]


@pytest.fixture(scope="module")
def deployed_oracle(decentralised_oracle, alice):
    yield decentralised_oracle.deploy(
        cvxCRV_POOL_ADDRESS,
        CRVUSD_CHAINLINK_ORACLE,
        {"from": alice},
    )


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    pass
