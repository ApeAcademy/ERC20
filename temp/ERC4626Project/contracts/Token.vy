# @version 0.3.4

from vyper.interfaces import ERC20
import ERC4626 as ERC4626


implements: ERC20
implements: ERC4626

# ERC20 Token Metadata
NAME: constant(String[20]) = "MyToken"
SYMBOL: constant(String[5]) = "Token"
DECIMALS: constant(uint8) = 18

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
##### ERC4626 #####

asset: public(ERC20)

event Deposit:
    depositor: indexed(address)
    receiver: indexed(address)
    assets: uint256
    shares: uint256

event Withdraw:
    withdrawer: indexed(address)
    receiver: indexed(address)
    owner: indexed(address)
    assets: uint256
    shares: uint256

owner: public(address)


@external
def __init__(asset: ERC20):
    self.owner = msg.sender
    self.totalSupply = 1000
    self.balanceOf[msg.sender] = 1000
    self.asset = asset


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

@view
@external
def totalAssets() -> uint256:
    return self.asset.balanceOf(self)


@view
@internal
def _convertToAssets(shareAmount: uint256) -> uint256:
    totalSupply: uint256 = self.totalSupply
    if totalSupply == 0:
        return 0

    # NOTE: `shareAmount = 0` is extremely rare case, not optimizing for it
    # NOTE: `totalAssets = 0` is extremely rare case, not optimizing for it
    return shareAmount * self.asset.balanceOf(self) / totalSupply


@view
@external
def convertToAssets(shareAmount: uint256) -> uint256:
    return self._convertToAssets(shareAmount)


@view
@internal
def _convertToShares(assetAmount: uint256) -> uint256:
    totalSupply: uint256 = self.totalSupply
    totalAssets: uint256 = self.asset.balanceOf(self)
    if totalAssets == 0 or totalSupply == 0:
        return assetAmount  # 1:1 price

    # NOTE: `assetAmount = 0` is extremely rare case, not optimizing for it
    return assetAmount * totalSupply / totalAssets


@view
@external
def convertToShares(assetAmount: uint256) -> uint256:
    return self._convertToShares(assetAmount)


@view
@external
def maxDeposit(owner: address) -> uint256:
    return max_value(uint256)


@view
@external
def previewDeposit(assets: uint256) -> uint256:
    return self._convertToShares(assets)


@external
def deposit(assets: uint256, receiver: address=msg.sender) -> uint256:
    shares: uint256 = self._convertToShares(assets)
    self.asset.transferFrom(msg.sender, self, assets)

    self.totalSupply += shares
    self.balanceOf[receiver] += shares
    log Deposit(msg.sender, receiver, assets, shares)
    return shares


@view
@external
def maxMint(owner: address) -> uint256:
    return max_value(uint256)


@view
@external
def previewMint(shares: uint256) -> uint256:
    assets: uint256 = self._convertToAssets(shares)

    # NOTE: Vyper does lazy eval on if, so this avoids SLOADs most of the time
    if assets == 0 and self.asset.balanceOf(self) == 0:
        return shares  # NOTE: Assume 1:1 price if nothing deposited yet

    return assets

@external
def mint(shares: uint256, receiver: address=msg.sender) -> uint256:
    assets: uint256 = self._convertToAssets(shares)

    if assets == 0 and self.asset.balanceOf(self) == 0:
        assets = shares  # NOTE: Assume 1:1 price if nothing deposited yet

    self.asset.transferFrom(msg.sender, self, assets)

    self.totalSupply += shares
    self.balanceOf[receiver] += shares
    log Deposit(msg.sender, receiver, assets, shares)
    return assets

@view
@external
def maxWithdraw(owner: address) -> uint256:
    return max_value(uint256)  # real max is `self.asset.balanceOf(self)`


@view
@external
def previewWithdraw(assets: uint256) -> uint256:
    shares: uint256 = self._convertToShares(assets)

    # NOTE: Vyper does lazy eval on if, so this avoids SLOADs most of the time
    if shares == assets and self.totalSupply == 0:
        return 0  # NOTE: Nothing to redeem

    return shares


@external
def withdraw(assets: uint256, receiver: address=msg.sender, owner: address=msg.sender) -> uint256:
    shares: uint256 = self._convertToShares(assets)

    # NOTE: Vyper does lazy eval on if, so this avoids SLOADs most of the time
    if shares == assets and self.totalSupply == 0:
        raise  # Nothing to redeem

    if owner != msg.sender:
        self.allowance[owner][msg.sender] -= shares

    self.totalSupply -= shares
    self.balanceOf[owner] -= shares

    self.asset.transfer(receiver, assets)
    log Withdraw(msg.sender, receiver, owner, assets, shares)
    return shares


@view
@external
def maxRedeem(owner: address) -> uint256:
    return max_value(uint256)  # real max is `self.totalSupply`


@view
@external
def previewRedeem(shares: uint256) -> uint256:
    return self._convertToAssets(shares)


@external
def redeem(shares: uint256, receiver: address=msg.sender, owner: address=msg.sender) -> uint256:
    if owner != msg.sender:
        self.allowance[owner][msg.sender] -= shares

    assets: uint256 = self._convertToAssets(shares)
    self.totalSupply -= shares
    self.balanceOf[owner] -= shares

    self.asset.transfer(receiver, assets)
    log Withdraw(msg.sender, receiver, owner, assets, shares)
    return assets
