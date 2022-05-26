import ape
{%- if cookiecutter.permitable == 'y' %}
import eip712
{%- endif %}

#Standard test comes from the interpretation of EIP-20 
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

def test_initial_state(token, owner):
    """
    Test inital state of the contract.
    """
    # Check the token meta matches the deployment 
    #token.method_name() has access to all the methods in the smart contract.
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
    assert token.totalSupply() == 1000
    assert token.balanceOf(owner) == 1000 
{%- endif %}

def test_transfer(token, owner, accounts):
    """
    Transfer must transfer an amount to an address.
    Must fire Transfer Event.
    Should throw an error of balance if sender does not have enough.
    """
    receiver = accounts[1]

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 1000

    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 0

#token.method_name() has access to all the methods in the smart contract.
    tx = token.transfer(receiver, 100, sender=owner)

# validate that Transfer Log is correct
#https://docs.apeworx.io/ape/stable/methoddocs/api.html?highlight=decode#ape.api.networks.EcosystemAPI.decode_logs
    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].receiver == receiver
    assert logs[0].amount == 100


    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 100

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 900


    # Expected insufficient funds failure
    # ape.reverts: Regress the current call using the given snapshot ID. 
    # Allows developers to go back to a previous state.
    # https://docs.apeworx.io/ape/stable/methoddocs/api.html?highlight=revert
    with ape.reverts():
        token.transfer(owner, 200, sender=receiver)
    
#Note Transfers of 0 values MUST be treated as normal transfers 
# and fire the Transfer event.
    tx = token.transfer(owner, 0, sender=owner)


def test_transfer_from(token, owner, accounts):
    """
    Transfer tokens to an address.
    Transfer operator may not be owner.
    Approve must be valid to be a spender.
    """
    receiver, spender = accounts[1:3]

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 1000

    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 0

    # Spender with no allowance cannot send tokens on someone behalf
    with ape.reverts():
        token.transferFrom(owner, receiver, 300, sender=spender)

        
    # get approval for allowance from owner
    tx = token.approve(spender, 300, sender=owner)

    logs = list(tx.decode_logs(token.Approval))
    assert len(logs) == 1
    assert logs[0].owner == owner
    assert logs[0].spender == spender
    assert logs[0].amount == 300
    
    assert token.allowance(owner,spender) == 300

    # with auth use the allowance to send to receiver via spender(operator)
    tx = token.transferFrom(owner, receiver, 200, sender=spender)

    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].receiver == receiver
    assert logs[0].amount == 200
    
    assert token.allowance(owner,spender) == 100

    # cannot exceed authorized allowance
    with ape.reverts():
        token.transferFrom(owner, receiver, 200, sender=spender)
    

    # transferFrom 100 tokens
    token.transferFrom(owner, receiver, 100, sender=spender) 
    assert token.balanceOf(spender) == 0
    assert token.balanceOf(receiver) == 300
    assert token.balanceOf(owner) == 700


def test_approve(token, owner, accounts):
    """
    Check the authorization of an operator(spender).
    Check the logs of Approve.
    """
    spender = accounts[1]

    tx = token.approve(spender, 300, sender=owner)

    logs = list(tx.decode_logs(token.Approval))
    assert len(logs) == 1
    assert logs[0].owner == owner
    assert logs[0].spender == spender
    assert logs[0].amount == 300
    
    assert token.allowance(owner,spender) == 300

    
    #Set auth balance to 0 and check to make sure no attacks vectors
    #THOUGH The contract itself shouldn’t enforce it, 
    #to allow backwards compatibility with contracts deployed before
    tx = token.approve(spender, 0, sender=owner)

    logs = list(tx.decode_logs(token.Approval))
    assert len(logs) == 1
    assert logs[0].owner == owner
    assert logs[0].spender == spender
    assert logs[0].amount == 0
    
    assert token.allowance(owner,spender) == 0

{%- if cookiecutter.mintable == 'y' %}
def test_mint(token, owner, accounts):
    """
    Create an approved amount of tokens.
    """
    receiver = accounts[1]

    totalSupply = token.totalSupply()
    assert totalSupply == 1000

    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 0

    tx = token.mint(receiver, 420, sender=owner)

    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].receiver == receiver
    assert logs[0].amount == 420

    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 420

    totalSupply = token.totalSupply()
    assert totalSupply == 1420
{%- endif %}
    

{%- if cookiecutter.burnable == 'y' %}
def test_mint(token, owner):
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
#Test Permitpip
class Permit(eip712.EIP712Message):
    owner: "address"
    spender: "address"
    value: "uint256"
    nonce: "uint256"
    deadline: "uint256"


def test_permit(chain,token,owner):
    """
    validate that expiry is still valid
    permit an address(operator) to send an amount to another address
    validate that amount is correct in the reciever
    validate that nonce is correct 
    """
    spender = accounts[1]
    amount = 100
    nonce = token.nonce(owner)
    deadline = chain.pending_timestamp + 60
    assert token.allowance(owner,spender) == 0
    permit = Permit(owner.address, spender.address, amount, nonce, deadline)
    signature = owner.sign_message(permit.as_signable_message())
    
    with ape.reverts():
        token.permit(spender, spender, amount, deadline, signature, sender=spender)
    with ape.reverts():
        token.permit(owner, owner, amount, deadline, signature, sender=spender)
    with ape.reverts():
        token.permit(owner, spender, amount+1, deadline, signature, sender=spender)
    with ape.reverts():
        token.permit(owner, spender, amount, deadline+1, signature, sender=spender)
    
    token.permit(owner, spender, amount, deadline, signature, sender=spender)

    assert token.allowance(owner,spender) == 100
{%- endif %}


