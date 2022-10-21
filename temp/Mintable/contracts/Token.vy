# @version 0.3.4

from vyper.interfaces import ERC20


implements: ERC20

# ERC20 Token Metadata
NAME: constant(String[20]) = "MyToken"
SYMBOL: constant(String[5]) = "TEST"
DECIMALS: constant(uint8) = 12

# ERC20 State Variables
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

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
isMinter: public(HashMap[address, bool])


@external
def __init__():
    self.owner = msg.sender
    self.totalSupply = 1000
    self.balanceOf[msg.sender] = 1000


@pure
@external
def name() -> String[20]:
    return NAME


@pure
@external
def symbol() -> String[5]:
    return SYMBOL


@pure
@external
def decimals() -> uint8:
    return DECIMALS


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(sender:address, receiver: address, amount: uint256) -> bool:
    self.allowance[sender][msg.sender] -= amount
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(sender, receiver, amount)

    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    """
    @param spender The address that will execute on owner behalf.
    @param amount The amount of token to be transfered.
    """
    self.allowance[msg.sender][spender] = amount

    log Approval(msg.sender, spender, amount)

    return True
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

    log Transfer(empty(address), receiver, amount)

    return True

@external
def addMinter(minter: address):
    assert msg.sender == self.owner
    self.isMinter[msg.sender] = True
