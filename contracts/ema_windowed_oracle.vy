# @version 0.3.1


interface StableSwap:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view

interface ChainlinkOracle:
    def latestAnswer() -> uint256: view


curve_pool: public(address)
chainlink_oracle: public(address)
ema_swap_rate: public(uint256)
alpha: public(uint256)


@external
def __init__(
    curve_pool: address,
    chainlink_oracle: address,
    initial_swap_rate: uint256,
    window_length_blocks: uint256
):

    self.curve_pool = curve_pool
    self.chainlink_oracle = chainlink_oracle
    self.ema_swap_rate = initial_swap_rate
    self.alpha = 2 / (window_length_blocks + 1) * 10 ** 18


@external
def update_ema_rate():
    # averaging logic: https://stackoverflow.com/a/23493727
    # get swap rate for 1 cvxCRV to CRV
    _latest_swap_rate: uint256 = StableSwap(self.curve_pool).get_dy(1, 0, 10 ** 18) * 10 ** 18 / 10 ** 18

    self.ema_swap_rate = (self.alpha * _latest_swap_rate + (10 ** 18 - self.alpha) * self.ema_swap_rate) / 10 ** 18


@external
@view
def latestAnswer() -> uint256:

    return ChainlinkOracle(self.chainlink_oracle).latestAnswer() * 10**10 * self.ema_swap_rate / 10 ** 18
