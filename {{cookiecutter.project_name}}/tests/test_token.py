from ctypes import addressof
from inspect import signature
import ape
import eip712


#Standard test comes from the interpretation of EIP-20 
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

# Test inital state of the contract
def test_initial_state(token, owner):
    # Check the token meta matches the deployment 
    assert token.name() == "Token"
    assert token.symbol() == "TKN"
    assert token.decimals() == 18

    # Check of intial state of authorization
    assert token.owner() == owner

    # Check intial balance of tokens
    assert token.totalSupply() == 1000
    assert token.balanceOf(owner) == 1000 

#Test Transfer
# Transfer value of amount to an address
# Must fire the transfer event
# Should throw an error of balance of sender does not have enough
def test_transfer(token, owner, accounts) -> bool:
    """
    token call all the methods on the token fixture. because ape is awesome
    ape python interface to python smart contract.

    for example you wan to test transfer
    
    """
    receiver = accounts[1]

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 1000

    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 0


    tx = token.transfer(receiver, 100, sender=owner)
    # Callers MUST handle false from returns (bool success). 
    # Callers MUST NOT assume that false is never returned!
    #assert tx.return_value == True

    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].receiver == receiver
    assert logs[0].amount == 100
#https://docs.apeworx.io/ape/stable/methoddocs/api.html?highlight=decode#ape.api.networks.EcosystemAPI.decode_logs


    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 100

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 900


    #expected insufficient funds failure
    with ape.reverts():
        token.transfer(owner, 200, sender=receiver)
    
#Note Transfers of 0 values MUST be treated as normal transfers 
# and fire the Transfer event.
    tx = token.transfer(owner, 0, sender=owner)
    #assert tx.return_value == True


#This standard provides basic functionality:
# to transfer tokens, 
# as well as allow tokens to be approved 
# so they can be spent by another on-chain third party.
def test_transfer_from(token, owner, accounts):

    receiver, spender = accounts[1:3]

    owner_balance = token.balanceOf(owner)
    assert owner_balance == 1000

    receiver_balance = token.balanceOf(receiver) 
    assert receiver_balance == 0

    # Spender with no allowance cannot send tokens on someone behalf
    with ape.reverts():
        token.transferFrom(owner, receiver, 300, sender=spender)

        
    #get approval for allowance from owner
    tx = token.approve(spender, 300, sender=owner)
    #assert tx.return_value == True

    logs = list(tx.decode_logs(token.Approval))
    assert len(logs) == 1
    assert logs[0].owner == owner
    assert logs[0].spender == spender
    assert logs[0].amount == 300
    
    assert token.allowance(owner,spender) == 300

    # with auth use the allowance to send to receiver via spender(operator)
    tx = token.transferFrom(owner, receiver, 200, sender=spender)    
    #assert tx.return_value == True

    logs = list(tx.decode_logs(token.Transfer))
    assert len(logs) == 1
    assert logs[0].sender == owner
    assert logs[0].receiver == receiver
    assert logs[0].amount == 200
    
    assert token.allowance(owner,spender) == 100

    # cannot exceed authorized allowance
    with ape.reverts():
        token.transferFrom(owner, receiver, 200, sender=spender)
    

    # transferFrom 100
    token.transferFrom(owner, receiver, 100, sender=spender) 
    assert token.balanceOf(spender) == 0
    assert token.balanceOf(receiver) == 300
    assert token.balanceOf(owner) == 700



#Test Approve
# Check the auth of an operator
# set auth balance to 0 and check to make sure no attacks vectors
#  THOUGH The contract itself shouldn’t enforce it, 
# to allow backwards compatibility with contracts deployed before
def test_approve(token, owner):
    pass
    #UC 1no one can send a token on you behalf
    #UC 2 any approved op cannot send more than auth amount
    # check logs
    # check the return value
    # check how much is allowed to send
# allowance:
# Returns the amount which _spender is still allowed to withdraw from _owner.

#Test Permit:

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

    # the permit allows you to approve

