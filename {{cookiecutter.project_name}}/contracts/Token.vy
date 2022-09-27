# @version 0.3.4

from vyper.interfaces import ERC20
{%- if cookiecutter.ERC4626 == 'y' %}
import ERC4626 as ERC4626
{%- endif %}


implements: ERC20
{%- if cookiecutter.ERC4626 == 'y' %}
implements: ERC4626
{%- endif %}

# ERC20 Token Metadata
NAME: constant(String[20]) = "{{cookiecutter.token_name}}"
SYMBOL: constant(String[5]) = "{{cookiecutter.token_symbol}}"
DECIMALS: constant(uint8) = {{cookiecutter.token_decimals}}

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

{%- if cookiecutter.ERC4626 == 'y' %}
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

{%- endif %}

owner: public(address)
{%- if cookiecutter.minter_role == "y" %}
isMinter: public(HashMap[address, bool])
{%- endif %}
{%- if cookiecutter.permitable == 'y' %}

nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')
{%- endif %}


@external
def __init__({%- if cookiecutter.ERC4626 == 'y' %}asset: ERC20{%- endif %}):
    self.owner = msg.sender
{%- if cookiecutter.premint == 'y' %}
    self.totalSupply = {{cookiecutter.premint_amount}}
    self.balanceOf[msg.sender] = {{cookiecutter.premint_amount}}
{%- else %}
    self.totalSupply = 1000
    self.balanceOf[msg.sender] = 1000
{%- endif %}

{%- if cookiecutter.ERC4626 == 'y' %}
    self.asset = asset
{%- endif %}

{%- if cookiecutter.permitable == 'y' %}

    # EIP-712
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(NAME),
            keccak256("1.0"),
            _abi_encode(chain.id, self)
        )
    )
{%- endif %}


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

{%- if cookiecutter.ERC4626 == 'y' %}

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

{%- endif %}

{%- if cookiecutter.burnable == 'y' %}
@external
def burn(amount: uint256):
    """
    @notice Burns the supplied amount of tokens from the sender wallet.
    @param amount The amount of token to be burned.
    """
    self.balanceOf[msg.sender] -= amount
    self.totalSupply -= amount

    log Transfer(msg.sender, empty(address), amount)
{%- endif %}

{%- if cookiecutter.ERC4626 == 'y' % and if cookiecutter.mintable == 'n'}

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


{%- else %}
@external
def mint(receiver: address, amount: uint256) -> bool:
    """
    @notice Function to mint tokens
    @param receiver The address that will receive the minted tokens.
    @param amount The amount of tokens to mint.
    @return A boolean that indicates if the operation was successful.
    """
    {% if cookiecutter.minter_role == "y" %}
    assert msg.sender == self.owner or self.isMinter[msg.sender], "Access is denied."
    {%- else %}
    assert msg.sender == self.owner "Access is denied."
    {%- endif %}

    self.totalSupply += amount
    self.balanceOf[receiver] += amount

    log Transfer(empty(address), receiver, amount)

    return True
    {%- endif %}
{%- endif %}

{%- if cookiecutter.ERC4626 == 'y' %}

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

{%- endif %}


{%- if cookiecutter.minter_role == "y" %}

@external
def addMinter(minter: address):
    assert msg.sender == self.owner
    self.isMinter[msg.sender] = True
{%- endif %}
{%- if cookiecutter.permitable == "y" %}


@external
def permit(owner: address, spender: address, amount: uint256, expiry: uint256, signature: Bytes[65]) -> bool:
    """
    @notice
        Approves spender by owner's signature to expend owner's tokens.
        See https://eips.ethereum.org/EIPS/eip-2612.
    @param owner The address which is a source of funds and has signed the Permit.
    @param spender The address which is allowed to spend the funds.
    @param amount The amount of tokens to be spent.
    @param expiry The timestamp after which the Permit is no longer valid.
    @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v.
    @return True, if transaction completes successfully
    """
    assert owner != empty(address)  # dev: invalid owner
    assert expiry == 0 or expiry >= block.timestamp  # dev: permit expired
    nonce: uint256 = self.nonces[owner]
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(
                _abi_encode(
                    PERMIT_TYPE_HASH,
                    owner,
                    spender,
                    amount,
                    nonce,
                    expiry,
                )
            )
        )
    )
    # NOTE: signature is packed as r, s, v
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature
    self.allowance[owner][spender] = amount
    self.nonces[owner] = nonce + 1
    log Approval(owner, spender, amount)

    return True
{%- endif %}
