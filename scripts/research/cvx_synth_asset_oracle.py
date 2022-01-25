from abc import abstractmethod

import brownie


class SyntheticOracle:
    dampened_rate: int = 0
    averaged_indices: int = 0

    @abstractmethod
    def latestAnswer(self, external_oracle_price: int) -> int:
        """External Oracle is an established of the oracle the derivative
        asset is being swapped into.

        :param external_oracle_price:
        :return:
        """
        raise NotImplementedError

    @abstractmethod
    def update_dampened_rate(self, swap_rate: int):
        """Calculate a dampened swap rate from derivative to source asset

        :param swap_rate:
        :return:
        """
        raise NotImplementedError


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
class EMARateOracle(SyntheticOracle):

    def update_dampened_rate(self, swap_rate: int):
        # averaging logic: https://stackoverflow.com/a/23493727

        self.averaged_indices += 1
        self.dampened_rate = int(
            (
                    self.dampened_rate *
                    (self.averaged_indices - 1) +
                    swap_rate
            ) / self.averaged_indices
        )

    def latestAnswer(self, external_oracle_price: int) -> int:

        return int(
            external_oracle_price * 10**10 * self.dampened_rate / 10 ** 18
        )


class SlidingWindowEMAOracle(SyntheticOracle):

    def __init__(self, num_blocks_in_window: int, initial_dampened_rate: int):

        self.alpha = int(2 / (num_blocks_in_window + 1) * 1E18)
        self.dampened_rate = initial_dampened_rate

    def update_dampened_rate(self, swap_rate: int):

        self.dampened_rate = int(
            self.alpha * swap_rate + (1E18 - self.alpha) * self.dampened_rate
        )

    def latestAnswer(self, external_oracle_price: int) -> int:

        return int(
            external_oracle_price * 10**10 * self.dampened_rate / 10 ** 18
        )

