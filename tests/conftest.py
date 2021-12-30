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


@pytest.fixture(scope="module")
def token(alice):
    weth = MintableForkToken("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
    weth._mint_for_testing(alice, 1_000_000 * 10 ** weth.decimals())
    alice_weth_balance = weth.balanceOf(alice)
    assert alice_weth_balance > 0
    yield weth


@pytest.fixture(scope="module")
def deployed_oracle_with_bounty(deployed_oracle, alice, token):
    _amount = 100 * 10 ** token.decimals()
    token.approve(deployed_oracle, _amount, {"from": alice})
    deployed_oracle.deposit_bounty(token.address, _amount, {"from": alice})
    contract_weth_balance = token.balanceOf(deployed_oracle.address)
    assert contract_weth_balance > 0
    yield deployed_oracle


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    pass
