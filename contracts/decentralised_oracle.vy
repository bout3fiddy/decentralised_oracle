# @version 0.3.1


interface StableSwap:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view

interface ChainlinkOracle:
    def latestAnswer() -> uint256: view


event OraclePriceUpdate:
    _chainlink_price: uint256
    _ema_pool_swap_rate: uint256
    _oracle_price: uint256


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
    # get swap rate for 1000 CRV to cvxCRV
    self.latest_swap_rate = StableSwap(CURVE_POOL).get_dy(1, 0, 10 ** 21) * 10 ** 18 / 10 ** 21
    self.averaged_indices += 1

    _ema_swap_rate: uint256 = (
        self.ema_swap_rate * (self.averaged_indices - 1) + self.latest_swap_rate
    ) / self.averaged_indices

    return _ema_swap_rate


@external
def update_oracle() -> uint256:

    # add logic for ensuring that the oracle does not get updated more often than it should:
    if block.timestamp - self.oracle_update_epoch < 3600:
        return self.latest_oracle_price

    # get exponential moving average swap rate:   
    _ema_swap_rate: uint256 = self._get_exponential_moving_average_rate()

    # get and store chainlink price:
    _chainlink_price: uint256 = ChainlinkOracle(CHAINLINK_ORACLE).latestAnswer() * 10**10
    
    # oracle price is:
    self.latest_oracle_price = _chainlink_price * _ema_swap_rate / 10 ** 18

    # update oracle epoch and log price
    self.oracle_update_epoch = block.timestamp
    log OraclePriceUpdate(_chainlink_price, _ema_swap_rate, self.latest_oracle_price)

    return self.latest_oracle_price