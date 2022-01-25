from brownie.network import contract
import pytest
from brownie_tokens import MintableForkToken


cvxCRV_POOL_ADDRESS = "0x9D0464996170c6B9e75eED71c68B99dDEDf279e8"
CRVUSD_CHAINLINK_ORACLE = "0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f"
INITIAL_SWAP_RATE = 0.997 * 1e18
WINDOW_LENGTH = 1000


@pytest.fixture(scope="session")
def alice(accounts):
    return accounts[0]


@pytest.fixture(scope="session")
def charlie(accounts):
    return accounts[1]


@pytest.fixture(scope="module")
def deployed_ema_oracle(ema_rate_oracle, alice):
    yield ema_rate_oracle.deploy(
        cvxCRV_POOL_ADDRESS,
        CRVUSD_CHAINLINK_ORACLE,
        {"from": alice},
    )


@pytest.fixture(scope="module")
def deployed_ema_windowed_oracle(ema_windowed_oracle, alice):
    yield ema_windowed_oracle.deploy(
        cvxCRV_POOL_ADDRESS,
        CRVUSD_CHAINLINK_ORACLE,
        INITIAL_SWAP_RATE,
        WINDOW_LENGTH,
        {"from": alice},
    )


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    pass
