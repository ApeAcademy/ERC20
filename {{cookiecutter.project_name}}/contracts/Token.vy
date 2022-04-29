from vyper.interfaces import ERC20

implements: ERC20

# ERC20 Token Metadata
NAME: constant(String[20]) = "{{cookiecutter.token_name}}"
SYMBOL: constant(String[5]) = "{{cookiecutter.token_symbol}}"
DECIMALS: constant(uint8) = {{cookiecutter.token_decimals}}

# ERC20 State Variables
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address ,HashMap[address, uint256]])

# Events
# 3 params, indexed means that params is index by the eth note client, you can trigger 
# you can filter on indexed
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval: 
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256
    
{%- if cookiecutter.premint == 'y' %} 
@external
def __init__():
    self.totalSupply = {{cookiecutter.premint_amount}}
    self.balanceOf[msg.sender] = {{cookiecutter.premint_amount}}
{%- endif %}

# Transfer def
@external 
def transfer(receiver: address, amount: uint256) -> bool:
    # safe math by default, require is not needed
    # doc string to include visual example
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(msg.sender, receiver, amount)

    return True

# Transfer from
@external 
def transferFrom(sender:address, receiver: address, amount: uint256) -> bool:
    self.allowance[sender][msg.sender] -= amount
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(sender, receiver, amount)


    return True

# Approve so the sender can allow people to send
# detuct amount on your behalf
@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount

    log Approval(msg.sender, spender, amount)
    
    return True


