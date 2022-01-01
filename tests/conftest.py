from brownie.network import contract
import pytest
from brownie_tokens import MintableForkToken


NAME = "cvxCRV Oracle"


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
        {"from": alice},
    )


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    pass
