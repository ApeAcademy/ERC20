import pytest
from ape import Contract
{%- if cookiecutter.permitable == 'y' %}
from eip712.messages import EIP712Message


@pytest.fixture(scope="session")
def Permit(chain, token):
    class Permit(EIP712Message):
        _name_: "string" = "{{ cookiecutter.token_name }}"
        _version_: "string" = "1.0"
        _chainId_: "uint256" = chain.chain_id
        _verifyingContract_: "address" = token.address

        owner: "address"
        spender: "address"
        value: "uint256"
        nonce: "uint256"
        deadline: "uint256"

    return Permit
{%- endif %}


@pytest.fixture(scope="session")
def owner(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def receiver(accounts):
    return accounts[1]


{%- if cookiecutter.ERC4626 == "y" %}
@pytest.fixture(scope="session")
def asset():
    return Contract("0x6B175474E89094C44Da98b954EedeAC495271d0F")  # DAI Ethereum Mainnet


{%- endif %}
@pytest.fixture(scope="session")
def token(owner, project{%- if cookiecutter.ERC4626 == "y" %}, asset{% endif %}):
    return owner.deploy(project.Token{%- if cookiecutter.ERC4626 == "y" %}, asset{% endif %})

