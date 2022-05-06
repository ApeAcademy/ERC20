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
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval: 
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256 

owner: public(address)
{%- if cookiecutter.minter == "y" %}
isMinter: public(HashMap[address, bool])
{%- endif %}

    
{%- if cookiecutter.premint == 'y' %} 

@external
def __init__():
    self.owner = msg.sender
    self.totalSupply = {{cookiecutter.premint_amount}}
    self.balanceOf[msg.sender] = 1000
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


{%- if cookiecutter.burnable == 'y' %} 

#Burnable
@external
def burn(amount: uint256):
    """
    @notice Burns the supplied amount of tokens from the sender wallet.
    @param amount The amount of token to be burned.
    """
    self.balanceOf[msg.sender] -= amount
    self.totalSupply -= amount

    log Transfer(msg.sender, ZERO_ADDRESS, amount)
{%- endif %}

{%- if cookiecutter.owner == "y" %} 

#Mint
@external
def mint(receiver: address, amount: uint256) -> bool:
    """
    @notice Function to mint tokens
    @param receiver The address that will receive the minted tokens.
    @param amount The amount of tokens to mint.
    @return A boolean that indicates if the operation was successful.
    """
    assert msg.sender == self.owner or self.isMinter[msg.sender], "Access is denied."
    

    self.totalSupply += amount
    self.balanceOf[receiver] += amount

    log Transfer(ZERO_ADDRESS, receiver, amount)
    return True
{%- endif %}

{%- if cookiecutter.minter == "y" %}

@external
def addMinter(minter: address):
    assert msg.sender == self.owner
    self.isMinter[msg.sender] = True
{%- endif %}

