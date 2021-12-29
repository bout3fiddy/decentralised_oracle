# @version 0.3.1

from vyper.interfaces import ERC20


interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def decimals() -> uint256: view
    def balanceOf(_user: address) -> uint256: view

interface StableSwap:
    def coins(i: uint256) -> address: view
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view
    def calc_token_amount(amounts: uint256[N_STABLECOINS], is_deposit: bool) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: int128) -> uint256: view
    def add_liquidity(amounts: uint256[N_STABLECOINS], min_mint_amount: uint256): nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256): nonpayable
    def remove_liquidity(amount: uint256, min_amounts: uint256[N_STABLECOINS]): nonpayable
    def get_virtual_price() -> uint256: view


event CommitNewAdmin:
    deadline: indexed(uint256)
    admin: indexed(address)

event NewAdmin:
    admin: indexed(address)

event SetOracle:
    _token_address: indexed(address)
    _curve_pool_address: indexed(address)
    _chainlink_oracle_address: indexed(address)

event UpdateRewardRate:
    _token_address: indexed(address)
    _old_rate: uint256
    _new_rate: uint256

event NewVerifiedDepositor:
    _token_address: indexed(address)
    _old_depositor_address: indexed(address)
    _new_depositor_address: indexed(address)

event DepositBounty:
    _depositor: indexed(address)
    _amount: uint256

event ClaimReward:
    _receiver: indexed(address)
    _bounty_token: indexed(address)
    _amount: uint256
    _oracle_token: indexed(address)

event UpdateOracle:
    _oracle_keeper: indexed(address)
    _oracle_token_address: indexed(address)
    _oracle_price: uint256


struct BountyTokenInfo:
    rate: uint256
    is_whitelisted: bool
    verified_depositor: address


WETH_ADDRESS: address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEFAULT_REWARD_RATE: uint256 = 0
cvxCRV_CURVE_POOL_INDEX: int128 = 1
CRV_CURVE_POOL_INDEX: int128 = 0

admin: public(address)
transfer_ownership_deadline: public(uint256)
future_admin: public(address)

name: public(String[32])
token_ticker: public(String[32])
curve_pool_address: address
chainlink_oracle: address


@external
def __init__(_name: String[64], _token_ticker: String[32], _curve_pool: address, _chainlink_oracle: address):

    self.admin = msg.sender
    log SetAdmin(ZERO_ADDRESS, _admin)

    self.name = _name
    self.token_ticker = _token_ticker
    self.rate = DEFAULT_REWARD_RATE

    self.curve_pool_address = _curve_pool
    self.chainlink_oracle = _chainlink_oracle


# deposit and update bounty rates
@external
@nonreentrant('lock')
def deposit_bounty(_token_address: address, _amount: uint256):
    """
    @notice
    @dev
    @param
    """
    assert not self.is_paused  # cannot deposit if paused
    assert _token_address == WETH_ADDRESS  # can only deposit weth
    assert _amount > 0

    assert ERC20(_token_address).transferFrom(msg.sender, self, _amount)

    log DepositBounty(msg.sender, _amount)


# code for receiving bounty: you get a higher bounty the closer you are to every 5th minute:
@external
def reward_bounty():
    """
    @notice This module rewards a bounty to the oracle update caller, 
    which is at its max (== self.rate) when it is close to a 5 minute interval, 
    and decays exponentially the farther you get from it until 4 minutes past, 
    and recovers exponentially from 4 minutes and onwards until the closer you 
    get to the 5 minute interval, rinse, repeat.
    @dev
    @param
    """
    pass


# code for calculating the oracle price of the curve pool asset
@internal
def _get_swap_rates():
    """
    @notice
    @dev
    @param
    """

    return StableSwap()


@internal
def _get_median_swap_rate(i: int128, j: int128):
    """
    @notice
    @dev
    @param
    """

    swap_rates: uint256[5]
    for i in range(5):
        amount_swapped: uint256 = 10 ** i * 1E18
        swap_rates[i] = StableSwap(self.curve_pool_address).get_dy(1, 0, amount_swapped) / amount_swapped

    return StableSwap()


@external
def update_oracle():
    """
    @notice
    @dev
    @param
    """
    pass


@external
@view
def get_updated_price():
    """
    @notice
    @dev
    @param
    """
    pass


# admin methods:
@external
def pause():
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin  # dev: admin-only function
    self.is_paused = True


@external
def unpause():
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin  # dev: admin-only function
    self.is_paused = False


# copied/inspired from: https://etherscan.deth.net/address/0x0000000022d53366457f9d5e68ec105046fc4383
@external
def commit_transfer_ownership(_new_admin: address) -> bool:
    """
    @notice Initiate a transfer of contract ownership
    @dev Once initiated, the actual transfer may be performed three days later
    @param _new_admin Address of the new owner account
    @return bool success
    """
    assert msg.sender == self.admin  # dev: admin-only function
    assert self.transfer_ownership_deadline == 0  # dev: transfer already active

    deadline: uint256 = block.timestamp + 3*86400
    self.transfer_ownership_deadline = deadline
    self.future_admin = _new_admin

    log CommitNewAdmin(deadline, _new_admin)

    return True


@external
def apply_transfer_ownership() -> bool:
    """
    @notice Finalize a transfer of contract ownership
    @dev May only be called by the current owner, three days after a
         call to `commit_transfer_ownership`
    @return bool success
    """
    assert msg.sender == self.admin  # dev: admin-only function
    assert self.transfer_ownership_deadline != 0  # dev: transfer not active
    assert block.timestamp >= self.transfer_ownership_deadline  # dev: now < deadline

    new_admin: address = self.future_admin
    self.admin = new_admin
    self.transfer_ownership_deadline = 0

    log NewAdmin(new_admin)

    return True


@external
def revert_transfer_ownership() -> bool:
    """
    @notice Revert a transfer of contract ownership
    @dev May only be called by the current owner
    @return bool success
    """
    assert msg.sender == self.admin  # dev: admin-only function

    self.transfer_ownership_deadline = 0

    return True
