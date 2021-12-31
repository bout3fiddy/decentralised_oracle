# @version 0.3.1

from vyper.interfaces import ERC20


interface StableSwap:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view

interface ChainlinkOracle:
    def latestAnswer() -> uint256: view


event OraclePriceUpdate:
    _chainlink_price: uint256
    _ema_pool_swap_rate: uint256
    _oracle_price: uint256

event UpdateSwapQuantity:
    _new_quantity: uint256

event UpdateOracleMinFrequency:
    _old_freq: uint256
    _new_freq: uint256


MAX_AVERAGED_VALUES: constant(uint256) = 100
DEFAULT_MIN_ORACLE_UPDATE_IN_SECONDS: constant(int128) = 3600

name: public(String[32])
token_ticker: public(String[32])
admin: public(address)
transfer_ownership_deadline: public(uint256)
future_admin: public(address)
is_paused: public(bool)
curve_pool_address: public(address)
chainlink_oracle: public(address)

averaged_indices: public(uint256)
chainlink_price: public(uint256)
ema_swap_rate: public(uint256)
latest_swap_rate: public(uint256)
latest_oracle_price: public(uint256)
oracle_update_epoch: public(uint256)
min_oracle_update_time_seconds: public(uint256)


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
    self.name = _name
    self.is_paused = False
    
    # oracle settings
    self.token_ticker = _token_ticker
    self.curve_pool_address = _curve_pool
    self.chainlink_oracle = _chainlink_oracle
    self.chainlink_price = _init_chainlink_price
    self.latest_oracle_price = _init_chainlink_price
    self.ema_swap_rate = 10 ** 18 # 1E18
    self.latest_swap_rate = 10 ** 18
    self.min_oracle_update_time_seconds = DEFAULT_MIN_ORACLE_UPDATE_IN_SECONDS


# code for calculating the oracle price of the curve pool asset
@external
def set_min_oracle_update_frequency(_new_oracle_update_min_freq_in_seconds: uint256) -> bool:

    assert msg.sender == self.admin  # admin only2

    log UpdateOracleMinFrequency(self.min_oracle_update_time_seconds, _new_oracle_update_min_freq_in_seconds)
    self.min_oracle_update_time_seconds = _new_oracle_update_min_freq_in_seconds
    
    return True


@internal
def _get_swap_rate() -> uint256:

    # append cvxcrv:crv swap rate to swap_rates array. coin_index 0 is CRV, coin_index 1 is cvxCRV. 
    # We are interested in swaps from cvxCRV to CRV. We take averages for different swap quantities
    # as well.
    # multiply 10 ** 18 to the to numerator for easier handling of decimals
    _swap_rate_1: uint256 = (
        StableSwap(self.curve_pool_address).get_dy(1, 0, 10 ** 18) * 10 ** 18 / 10 ** 18
    )
    _swap_rate_10: uint256 = (
        StableSwap(self.curve_pool_address).get_dy(1, 0, 10 * 10 ** 18) * 10 ** 18 / 10 ** 18
    )
    _swap_rate_100: uint256 = (
        StableSwap(self.curve_pool_address).get_dy(1, 0, 100 * 10 ** 18) * 10 ** 18 / 10 ** 18
    )
    _swap_rate_1000: uint256 = (
        StableSwap(self.curve_pool_address).get_dy(1, 0, 1000 * 10 ** 18) * 10 ** 18 / 10 ** 18
    )

    self.latest_swap_rate = (_swap_rate_1 + _swap_rate_10 + _swap_rate_100 + _swap_rate_1000) / 4
    self.averaged_indices += 1   

    return self.latest_swap_rate


@internal
def _get_exponential_moving_average_rate() -> uint256:
    # averaging logic: https://stackoverflow.com/a/23493727

    _latest_swap_rate: uint256 = self._get_swap_rate()    
    _average_swap_rate: uint256 = self.ema_swap_rate * (self.averaged_indices - 1) / self.averaged_indices
    _average_swap_rate = _average_swap_rate + _latest_swap_rate / self.averaged_indices

    self.ema_swap_rate = _average_swap_rate

    return self.ema_swap_rate


@internal
def _get_chainlink_price() -> uint256:

    return ChainlinkOracle(self.chainlink_oracle).latestAnswer() * 10**10


@external
def update_oracle() -> uint256:

    # add logic for ensuring that the oracle does not get updated more often than it should:
    if block.timestamp - self.oracle_update_epoch < self.min_oracle_update_time_seconds:
        return self.latest_oracle_price

    # get exponential moving average swap rate:   
    self.ema_swap_rate = self._get_exponential_moving_average_rate()

    # get and store chainlink price:
    self.chainlink_price = self._get_chainlink_price()
    
    # oracle price is:
    self.latest_oracle_price = self.chainlink_price * self.ema_swap_rate / 10 ** 18

    # update oracle epoch and log price
    self.oracle_update_epoch = block.timestamp
    log OraclePriceUpdate(self.chainlink_price, self.ema_swap_rate, self.latest_oracle_price)

    return self.latest_oracle_price


@external
@view
def latestAnswer() -> uint256:
    return self.latest_oracle_price