# @version 0.3.1

from vyper.interfaces import ERC20


interface StableSwap:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view

interface ChainlinkOracle:
    def getLatestPrice() -> uint256: view


event CommitNewAdmin:
    deadline: indexed(uint256)
    admin: indexed(address)

event NewAdmin:
    admin: indexed(address)

event SetOracle:
    _token_address: indexed(address)
    _curve_pool_address: indexed(address)
    _chainlink_oracle_address: indexed(address)
    _swap_quantity: uint256

event OraclePriceUpdate:
    _chainlink_price: uint256
    _average_pool_swap_rate: uint256
    _oracle_price: uint256

event UpdateSwapQuantity:
    _new_quantity: uint256

event UpdateOracleMinFrequency:
    _old_freq: uint256
    _new_freq: uint256

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


WETH_ADDRESS: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
DEFAULT_REWARD_RATE: constant(uint256) = 0
DEFAULT_SWAP_QUANTITY: constant(uint256) = 1000000000000000000000
MAX_STORED_RATES: constant(uint256) = 100
DEFAULT_MIN_ORACLE_UPDATE_IN_SECONDS: constant(int128) = 3600

admin: public(address)
transfer_ownership_deadline: public(uint256)
future_admin: public(address)
is_paused: bool

name: public(String[32])
token_ticker: public(String[32])
reward_rate: public(uint256)

swap_quantity: uint256
swap_rates: HashMap[uint256, uint256]
filled_indices: uint256
append_to_index: uint256
curve_pool_address: address
chainlink_oracle: address
chainlink_price: uint256
average_swap_rate: uint256
latest_oracle_price: uint256
oracle_update_epoch: uint256
min_oracle_update_time_seconds: uint256


@external
def __init__(
    _name: String[32], 
    _token_ticker: String[32], 
    _curve_pool: address, 
    _chainlink_oracle: address,
    _init_chainlink_price: uint256,
    _init_oracle_update_epoch: uint256
):

    self.admin = msg.sender
    log NewAdmin(msg.sender)
    self.name = _name
    self.is_paused = False

    # bounty settings
    self.token_ticker = _token_ticker
    self.reward_rate = DEFAULT_REWARD_RATE
    
    # oracle settings
    self.curve_pool_address = _curve_pool
    self.chainlink_oracle = _chainlink_oracle
    self.swap_quantity = DEFAULT_SWAP_QUANTITY
    self.min_oracle_update_time_seconds = DEFAULT_MIN_ORACLE_UPDATE_IN_SECONDS
    self.chainlink_price = _init_chainlink_price * 10**10
    self.latest_oracle_price = _init_chainlink_price
    self.average_swap_rate = 10 ** 18 # 1E18
    self.oracle_update_epoch = 0  # keeping it zero so oracle update can be called without waiting

    self.filled_indices = 0
    self.append_to_index = 0


# deposit bounty
@external
def deposit_bounty(_token_address: address, _amount: uint256):

    assert not self.is_paused  # dev: cannot deposit if paused
    assert _token_address == WETH_ADDRESS  # dev: can only deposit weth
    assert _amount > 0
    assert ERC20(_token_address).transferFrom(msg.sender, self, _amount)

    log DepositBounty(msg.sender, _amount)


# code for receiving bounty: you get a higher bounty the closer you are to every 5th minute:
@internal
@payable
def _reward_bounty(_receiver_address: address):

    ERC20(WETH_ADDRESS).transferFrom(self, _receiver_address, self.reward_rate)


# code for calculating the oracle price of the curve pool asset
@external
def set_pool_swap_quantity(_quantity: uint256) -> bool:

    assert msg.sender == self.admin  # admin only
    self.swap_quantity = _quantity
    log UpdateSwapQuantity(_quantity)
    return True


@external
def set_min_oracle_update_frequency(_new_oracle_update_min_freq_in_seconds: uint256) -> bool:

    assert msg.sender == self.admin  # admin only2

    log UpdateOracleMinFrequency(self.min_oracle_update_time_seconds, _new_oracle_update_min_freq_in_seconds)
    self.min_oracle_update_time_seconds = _new_oracle_update_min_freq_in_seconds
    
    return True


@internal
def _get_swap_rates():

    # if append to index equals max stored rates, go back to 0 (earliest entry)
    # and overwrite it. This is for generating a rolling window such that once
    # MAX_STORED_RATES values are filled, we want to start replacing the older
    # swap_rates with newer rates.
    if self.append_to_index == MAX_STORED_RATES:
        self.append_to_index = 0

    # append cvxcrv:crv swap rate to swap_rates array. coin_index 0 is CRV, coin_index 1 is cvxCRV. 
    # We are interested in swaps from cvxCRV to CRV
    self.swap_rates[self.append_to_index] = StableSwap(self.curve_pool_address).get_dy(1, 0, self.swap_quantity) / self.swap_quantity
    
    # the filled indices tracks how much of the array is already filled. This helps
    # with averaging
    if self.filled_indices < MAX_STORED_RATES:
        self.filled_indices = self.filled_indices + 1
        self.append_to_index = self.append_to_index + 1


@internal
def _get_average_swap_rate() -> uint256:

    self._get_swap_rates()
    _sum_swap_rates: uint256 = 0
    for i in range(MAX_STORED_RATES):
        _sum_swap_rates += self.swap_rates[i]
    
    self.average_swap_rate = _sum_swap_rates / self.filled_indices

    return self.average_swap_rate


@external
def get_average_swap_rate() -> uint256:
    return self._get_average_swap_rate()


@external
def update_oracle() -> uint256:

    # add logic for ensuring that the oracle does not get updated more often than it should:
    if block.timestamp - self.oracle_update_epoch > self.min_oracle_update_time_seconds:
        return self.latest_oracle_price

    # get average swap rate:   
    self.average_swap_rate = self._get_average_swap_rate()

    # get and store chainlink price:
    self.chainlink_price = ChainlinkOracle(self.chainlink_oracle).getLatestPrice() * 10**10  # chainlink prices are in 8 decimals
    
    # oracle price is:
    self.latest_oracle_price = self.chainlink_price * self.average_swap_rate

    # update oracle epoch and log price
    self.oracle_update_epoch = block.timestamp
    log OraclePriceUpdate(self.chainlink_price, self.average_swap_rate, self.latest_oracle_price)

    # reward bounty to oracle update caller
    self._reward_bounty(msg.sender)

    return self.latest_oracle_price


@external
@view
def getLatestPrice() -> uint256:

    return self.latest_oracle_price


# admin methods:
@external
def pause() -> bool:

    assert msg.sender == self.admin  # dev: admin-only function
    self.is_paused = True

    return True


@external
def unpause() -> bool:

    assert msg.sender == self.admin  # dev: admin-only function
    self.is_paused = False

    return True


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
