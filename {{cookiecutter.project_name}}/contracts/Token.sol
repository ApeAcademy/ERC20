// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
{%- if cookiecutter.burnable == 'y' %} 
import "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol"; {%- endif %}
{%- if cookiecutter.pausable == 'y' %} 
import "@openzeppelin/security/Pausable.sol";  {%- endif %}
{%- if cookiecutter.permit == 'y' %} 
import "@openzeppelin/token/ERC20/extensions/draft-ERC20Permit.sol"; {%- endif %}
{%- if cookiecutter.votes == 'y' %} 
import "@openzeppelin/token/ERC20/extensions/ERC20Votes.sol"; {%- endif %}
{%- if cookiecutter.flashminting == 'y' %} 
import "@openzeppelin/token/ERC20/extensions/ERC20FlashMint.sol"; {%- endif %}
{%- if cookiecutter.snapshot == 'y' %} 
import "@openzeppelin/token/ERC20/extensions/ERC20Snapshot.sol"; {%- endif %}


contract {{cookiecutter.smart_contract_file_name}} is ERC20 , Ownable 
{%- if cookiecutter.burnable == 'y' %}, ERC20Burnable {%- endif %}
{%- if cookiecutter.pausable == 'y' %}, Pausable {%- endif %}
{%- if cookiecutter.votes == 'y' %}, ERC20Votes  {%- endif %}
{%- if cookiecutter.flashminting == 'y' %}, ERC20FlashMint  {%- endif %}
{%- if cookiecutter.snapshot == 'y' %}, ERC20Snapshot  {%- endif %} {
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    constructor(string memory name_,
                string memory symbol_{%- if cookiecutter.premint == 'y' %}, 
                uint256 amount_ {%- endif %}
                ) ERC20("{{cookiecutter.token_name}}", "{{cookiecutter.token_symbol}}") 
    {%- if cookiecutter.permit == 'y' or (cookiecutter.votes == 'y') %} 
    ERC20Permit("{{cookiecutter.token_name}}") 
    {%- endif %}{

{%- if cookiecutter.premint == 'y' %} 
        _mint(msg.sender, amount_ * 10 ** decimals());
{%- endif %}
        _name = name_;
        _symbol = symbol_;
    }
    
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

        /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();

{%- if cookiecutter.spend_Allowance == 'y' %} 
        _spendAllowance(from, spender, amount);
{%- endif %}
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

{%- if cookiecutter.before_Token_Transfer == 'y' %} 
        _beforeTokenTransfer(from, to, amount);
{%- endif %}

    uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

{%- if cookiecutter.before_Token_Transfer == 'y' %} 
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        {%if cookiecutter.pausable == 'y' %}whenNotPaused{%- endif %}
        {%if cookiecutter.snapshot == 'y' %}override(ERC20, ERC20Snapshot){%- else %}override{%- endif %}
    {
        super._beforeTokenTransfer(from, to, amount);
    }
{%- endif %}

{%- if cookiecutter.after_Token_Transfer == 'y' %} 
    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        {%if cookiecutter.votes == 'y' %}override(ERC20, ERC20Votes){%- else %}override(ERC20){%- endif %}
    {
        super._afterTokenTransfer(from, to, amount);
    }
{%- endif %}

{%- if cookiecutter.snapshot == 'y' %} 
function snapshot() public onlyOwner {
        _snapshot();
    }
{%- endif %}

{%- if cookiecutter.pausable == 'y' %} 
    
        function pause() public onlyOwner {
        _pause();
    }
    
        function unpause() public onlyOwner {
        _unpause();
    }

{%- endif %}

{%- if cookiecutter.post_mint == 'y' %} 
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        {%if cookiecutter.votes == 'y' %}override(ERC20, ERC20Votes){%- else %}override(ERC20){%- endif %}
    {
        super._mint(to, amount);
    }
{%- endif %}

{%- if cookiecutter.burnable == 'y' %} 
    function _burn(address account, uint256 amount)
        internal
        {%if cookiecutter.votes == 'y' %}override(ERC20, ERC20Votes){%- else %}override(ERC20){%- endif %}
    {
        super._burn(account, amount);
    }
{%- endif %}
}
