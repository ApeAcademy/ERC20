import ape
import pytest

# Standard test comes from the interpretation of EIP-20
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"


def test_initial_state(token, owner):
    """
    Test inital state of the contract.
    """
    # Check the token meta matches the deployment
    # token.method_name() has access to all the methods in the smart contract.
    assert token.name() == "{{cookiecutter.token_name}}"
    assert token.symbol() == "{{cookiecutter.token_symbol}}"
    assert token.decimals() == {{cookiecutter.token_decimals}}

    # Check of intial state of authorization
    assert token.owner() == owner

    # Check intial balance of tokens
{%- if cookiecutter.premint == 'y' %}
    assert token.totalSupply() == {{cookiecutter.premint_amount}}
    assert token.balanceOf(owner) == {{cookiecutter.premint_amount}}
{%- else %}
    assert token.totalSupply() == 0
    assert token.balanceOf(owner) == 0
{%- endif %}


def test_transfer(token, owner, receiver):
    """
    Transfer must transfer an amount to an address.
    Must trigger Transfer Event.
    Should throw an error of balance if sender does not have enough funds.
    """
    owner_balance = token.balanceOf(owner)
{%- if cookiecutter.premint == 'y' %}
    assert owner_balance == {{cookiecutter.premint_amount}}
{%- else %}
    assert owner_balance == 1000
{%- endif %}

    receiver_balance = token.balanceOf(receiver)
    assert receiver_balance == 0

    # token.method_name() has access to all the methods in the smart contract.
    tx = token.transfer(receiver, 100, sender=owner)

    # validate that Transfer Log is correct
    # https://docs.apeworx.io/ape/stable/methoddocs/api.html?highlight=decode#ape.api.networks.EcosystemAPI.decode_logs
    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].receiver == receiver
    assert logs[0].amount == 100

    receiver_balance = token.balanceOf(receiver)
    assert receiver_balance == 100

    owner_balance = token.balanceOf(owner)
{%- if cookiecutter.premint == 'y' %}
    assert owner_balance == {{cookiecutter.premint_amount}} - 100
{%- else %}
    assert owner_balance == 900
{%- endif %}

    # Expected insufficient funds failure
    # ape.reverts: Reverts the current call using a given snapshot ID.
    # Allows developers to go back to a previous state.
    # https://docs.apeworx.io/ape/stable/methoddocs/api.html?highlight=revert
    with ape.reverts():
        token.transfer(owner, 200, sender=receiver)

    # NOTE: Transfers of 0 values MUST be treated as normal transfers
    # and trigger a Transfer event.
    tx = token.transfer(owner, 0, sender=owner)


def test_transfer_from(token, owner, accounts):
    """
    Transfer tokens to an address.
    Transfer operator may not be an owner.
    Approve must be valid to be a spender.
    """
    receiver, spender = accounts[1:3]

    owner_balance = token.balanceOf(owner)
{%- if cookiecutter.premint == 'y' %}
    assert owner_balance == {{cookiecutter.premint_amount}}
{%- else %}
    assert owner_balance == 1000
{%- endif %}

    receiver_balance = token.balanceOf(receiver)
    assert receiver_balance == 0

    # Spender with no approve permission cannot send tokens on someone behalf
    with ape.reverts():
        token.transferFrom(owner, receiver, 300, sender=spender)

    # Get approval for allowance from owner
    tx = token.approve(spender, 300, sender=owner)

    logs = list(tx.decode_logs(token.Approval))
    assert len(logs) == 1
    assert logs[0].owner == owner
    assert logs[0].spender == spender
    assert logs[0].amount == 300

    assert token.allowance(owner, spender) == 300

    # With auth use the allowance to send to receiver via spender(operator)
    tx = token.transferFrom(owner, receiver, 200, sender=spender)

    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].receiver == receiver
    assert logs[0].amount == 200

    assert token.allowance(owner, spender) == 100

    # Cannot exceed authorized allowance
    with ape.reverts():
        token.transferFrom(owner, receiver, 200, sender=spender)

    token.transferFrom(owner, receiver, 100, sender=spender)
    assert token.balanceOf(spender) == 0
    assert token.balanceOf(receiver) == 300
{%- if cookiecutter.premint == 'y' %}
    assert token.balanceOf(owner) == {{cookiecutter.premint_amount}} - 300
{%- else %}
    assert token.balanceOf(owner) == 700
{%- endif %}


def test_approve(token, owner, receiver):
    """
    Check the authorization of an operator(spender).
    Check the logs of Approve.
    """
    spender = receiver

    tx = token.approve(spender, 300, sender=owner)

    logs = list(tx.decode_logs(token.Approval))
    assert len(logs) == 1
    assert logs[0].owner == owner
    assert logs[0].spender == spender
    assert logs[0].amount == 300

    assert token.allowance(owner, spender) == 300

    # Set auth balance to 0 and check attacks vectors
    # though the contract itself shouldn’t enforce it,
    # to allow backwards compatibility
    tx = token.approve(spender, 0, sender=owner)

    logs = list(tx.decode_logs(token.Approval))
    assert len(logs) == 1
    assert logs[0].owner == owner
    assert logs[0].spender == spender
    assert logs[0].amount == 0

    assert token.allowance(owner, spender) == 0
{%- if cookiecutter.mintable == 'y' %}


def test_mint(token, owner, receiver):
    """
    Create an approved amount of tokens.
    """
    totalSupply = token.totalSupply()
{%- if cookiecutter.premint == 'y' %}
    assert token.totalSupply() == {{cookiecutter.premint_amount}}
{%- else %}
    assert token.totalSupply() == 1000
{%- endif %}

    receiver_balance = token.balanceOf(receiver)
    assert receiver_balance == 0

    tx = token.mint(receiver, 420, sender=owner)

    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == ZERO_ADDRESS
    assert logs[0].receiver == receiver.address
    assert logs[0].amount == 420

    receiver_balance = token.balanceOf(receiver)
    assert receiver_balance == 420

    totalSupply = token.totalSupply()
{%- if cookiecutter.premint == 'y' %}
    assert token.totalSupply() == {{cookiecutter.premint_amount}} + 420
{%- else %}
    assert token.totalSupply() == 1000 + 420
{%- endif %}


def test_add_minter(token, owner, accounts):
    """
    Test adding new minter.
    Must trigger MinterAdded Event.
    Must return true when checking if target isMinter
    """
    target = accounts[1]
    assert token.isMinter(target) is False
    token.addMinter(target, sender=owner)
    assert token.isMinter(target) is True


def test_add_minter_targeting_zero_address(token, owner):
    """
    Test adding new minter targeting ZERO_ADDRESS
    Must trigger a ContractLogicError (ape.exceptions.ContractLogicError)
    """
    target = ZERO_ADDRESS
    with pytest.raises(ape.exceptions.ContractLogicError) as exc_info:
        token.addMinter(target, sender=owner)
    assert exc_info.value.args[0] == "Cannot add zero address as minter."
{%- endif %}
{%- if cookiecutter.burnable == 'y' %}


def test_burn(token, owner):
    """
    Burn/Send amount of tokens to ZERO Address.
    """
    totalSupply = token.totalSupply()
    assert totalSupply == 1000

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 1000

    tx = token.burn(420, sender=owner)

    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].amount == 420

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 580

    totalSupply = token.totalSupply()
    assert totalSupply == 580
{%- endif %}
{%- if cookiecutter.permitable == 'y' %}


def test_permit(chain, token, owner, receiver, Permit):
    """
    Validate permit method for incorrect ownership, values, and timing
    """
    amount = 100
    nonce = token.nonces(owner)
    deadline = chain.pending_timestamp + 60
    assert token.allowance(owner, receiver) == 0
    permit = Permit(owner.address, receiver.address, amount, nonce, deadline)
    signature = owner.sign_message(permit.signable_message).encode_rsv()

    with ape.reverts():
        token.permit(receiver, receiver, amount, deadline, signature, sender=receiver)
    with ape.reverts():
        token.permit(owner, owner, amount, deadline, signature, sender=receiver)
    with ape.reverts():
        token.permit(owner, receiver, amount + 1, deadline, signature, sender=receiver)
    with ape.reverts():
        token.permit(owner, receiver, amount, deadline + 1, signature, sender=receiver)

    token.permit(owner, receiver, amount, deadline, signature, sender=receiver)

    assert token.allowance(owner, receiver) == 100
{%- endif %}
