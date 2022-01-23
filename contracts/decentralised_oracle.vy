# @version 0.3.1


interface StableSwap:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view

interface ChainlinkOracle:
    def latestAnswer() -> uint256: view


event SwapRateUpdate:
    _old_rate: uint256
    _current_rate: uint256


name: public(String[32])
CURVE_POOL: constant(address) = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8
CHAINLINK_ORACLE: constant(address) = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f

averaged_indices: public(uint256)
ema_swap_rate: public(uint256)
latest_swap_rate: public(uint256)
latest_oracle_price: public(uint256)
oracle_update_epoch: public(uint256)


@external
def __init__(
    _name: String[32], 
):

    self.name = _name


@internal
def _get_exponential_moving_average_rate() -> uint256:
    # averaging logic: https://stackoverflow.com/a/23493727
    # get swap rate for 1 cvxCRV to CRV
    self.latest_swap_rate = StableSwap(CURVE_POOL).get_dy(1, 0, 10 ** 18) * 10 ** 18 / 10 ** 18
    self.averaged_indices += 1

    _ema_swap_rate: uint256 = (
        self.ema_swap_rate * (self.averaged_indices - 1) + self.latest_swap_rate
    ) / self.averaged_indices

    log SwapRateUpdate(self.ema_swap_rate, _ema_swap_rate)
    self.ema_swap_rate = _ema_swap_rate

    return _ema_swap_rate


@external
def update_ema_rate():

    self._get_exponential_moving_average_rate()


@external
@view
def latestAnswer() -> uint256:

    _chainlink_price: uint256 = ChainlinkOracle(CHAINLINK_ORACLE).latestAnswer() * 10**10
    return _chainlink_price * self.ema_swap_rate / 10 ** 18
