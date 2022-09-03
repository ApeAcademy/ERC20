import ape
import pytest


# constants
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"


def test_add_minter(token, owner, accounts):
    """
    Test adding new minter.
    Must trigger MinterAdded Event.
    Must return true when checking if target isMinter
    """
    target = accounts[1]
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
