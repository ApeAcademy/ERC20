import pytest
from eip712.messages import EIP712Message


@pytest.fixture(scope="session")
def Permit(chain, token):
    class Permit(EIP712Message):
        _name_: "string" = "MyToken"
        _version_: "string" = "1.0"
        _chainId_: "uint256" = chain.chain_id
        _verifyingContract_: "address" = token.address

        owner: "address"
        spender: "address"
        value: "uint256"
        nonce: "uint256"
        deadline: "uint256"

    return Permit


@pytest.fixture(scope="session")
def owner(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def receiver(accounts):
    return accounts[1]

@pytest.fixture(scope="session")
def token(owner, project):
    return owner.deploy(project.Token)

