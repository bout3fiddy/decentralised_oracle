import brownie


class ConvexSynthAssetOracle:
    swap_from_id: int = 1  # cvxAsset coin index in pool
    swap_to_id: int = 0
    ema_swap_rate: int = 0
    averaged_indices: int = 0

    def __init__(
            self,
            curve_pool: brownie.Contract,
            chainlink_oracle: brownie.Contract,
            swap_quantity: int = 1E22  # get rates for 10000 cvxcrv

    ):

        self.curve_pool: brownie.Contract = curve_pool
        self.chainlink_oracle: brownie.Contract = chainlink_oracle
        self.swap_quantity = swap_quantity

    def update_ema_rate(self):
        # averaging logic: https://stackoverflow.com/a/23493727
        # get swap rate for 1 cvxCRV to CRV
        _latest_swap_rate: int = self.curve_pool.get_dy(
            1, 0, self.swap_quantity
        ) * 10 ** 18 / self.swap_quantity
        self.averaged_indices += 1

        self.ema_swap_rate = int(
            (
                    self.ema_swap_rate *
                    (self.averaged_indices - 1) +
                    _latest_swap_rate
            ) / self.averaged_indices
        )

    def latestAnswer(self) -> int:

        return int(
            self.chainlink_oracle.latestAnswer() *
            10**10 * self.ema_swap_rate / 10 ** 18
        )

    def get_latest_cvxAsset_price(self) -> float:

        return self.latestAnswer() / 1E18


# this version does not do any contract calls:
class ConvexSynthAssetOracleLite:
    ema_swap_rate: int = 0
    averaged_indices: int = 0

    def update_ema_rate(self, _latest_swap_rate: int):
        # averaging logic: https://stackoverflow.com/a/23493727
        # get swap rate for 1 cvxCRV to CRV

        self.averaged_indices += 1
        self.ema_swap_rate = int(
            (
                    self.ema_swap_rate *
                    (self.averaged_indices - 1) +
                    _latest_swap_rate
            ) / self.averaged_indices
        )

    def latestAnswer(self, chainlink_oracle_price: int) -> int:

        return int(
            chainlink_oracle_price * 10**10 * self.ema_swap_rate / 10 ** 18
        )

    def get_latest_cvxAsset_price(self, chainlink_oracle_price: int) -> float:

        return self.latestAnswer(chainlink_oracle_price) / 1E18
