def test_token(token):
    assert token



# Test inital state of the contract
def test_initial_state(token):
    # Check total supply, name, symbol and decimals are correctly set
    assert token.totalSupply() == {{cookiecutter.premint_amount}}
    assert token.name() == TOKEN_NAME
    assert token.symbol() == TOKEN_SYMBOL
    assert token.decimals() == TOKEN_DECIMALS



#This standard provides basic functionality:
# to transfer tokens, 
# as well as allow tokens to be approved 
# so they can be spent by another on-chain third party.


#Standard test comes from the interpretation of EIP-20 




# Callers MUST handle false from returns (bool success). 
# Callers MUST NOT assume that false is never returned!


#Test 1
# Total Supply must return a value


#Test 2
#BalanceOf should return a value of an address

#Test 3
# Transfer value of amount to an address
# Must fire the transfer event
# Should throw an error of balance of sender does not have enough

#Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.


#Test 4
# Transfer value of amount to an address
# Must fire the transfer event

#Test 4-5 can be to check the validity of Transfer event

#Test 6:
# Test that the transferFrom contract sends a value to an address
#The function SHOULD throw unless the _from account has deliberately authorized 
# the sender of the message via some mechanism.
#Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.


#Test 7
# Check the auth of an operator
# set auth balance to 0 and check to make sure no attacks vectors
#  THOUGH The contract itself shouldn’t enforce it, 
# to allow backwards compatibility with contracts deployed before

# Test 8
# allowance:
# Returns the amount which _spender is still allowed to withdraw from _owner.

#Test 9
# Transfer
#MUST trigger when tokens are transferred, including zero value transfers.
# A token contract which creates new tokens SHOULD trigger a Transfer event 
# with the _from address set to 0x0 when tokens are created.



#Test 10: 
# Approval
#MUST trigger on any successful call to approve(address _spender, uint256 _value).



{{cookiecutter.premint_amount}}