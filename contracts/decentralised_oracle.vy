from vyper.interfaces import ERC20


interface DecentralisedOracle:
    def owner(): -> address: view

interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def decimals() -> uint256: view
    def balanceOf(_user: address) -> uint256: view


event SetAdmin:
    _old_admin: indexed(address)
    _new_admin: indexed(address)

event SetOracle:
    _token_address: indexed(address)
    _curve_pool_address: indexed(address)
    _chainlink_oracle_address: indexed(address)

event UpdateRewardRate:
    _bounty_token_address: indexed(address)
    _token_address: indexed(address)
    _old_rate: uint256
    _new_rate: uint256

event DepositReward:
    _depositor: indexed(address)
    _bounty_token: indexed(address)
    _amount: uint256
    _reward_rate: uint256
    _oracle_token: uint256

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
    addr: address
    rate: uint256
    is_whitelisted: bool


admin: public(address)
NAME: public(String[32]) = ""
token_ticker: public(String[32])
deposit_address: public(address)
MAX_TOKEN_TYPES: immutable(int128) = 500
bounty_tokens: HashMap[address, BountyTokenInfo[MAX_TOKEN_TYPES]]
DEFAULT_REWARD_RATE: uint256 = 0


@external
def __init__(_name: String[64], _symbol: String[32]):

    self.admin = msg.sender
    log SetAdmin(ZERO_ADDRESS, _admin)

    self.name = _name
    self.token_ticker = _token_ticker


@external
def whitelist_bounty_token(_token_address: address):
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin

    self.bounty_tokens[_token_address] = BountyTokenInfo(
        {
            addr: _token_address,
            rate: DEFAULT_REWARD_RATE,
            is_whitelisted: True
        }
    )


@external
def blacklist_bounty_token(_token_address: address):
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin
    self.bounty_tokens[_token_address]


@external
@view
def is_whitelisted(_token_address):
    """
    @notice
    @dev
    @param
    """
    return _is_whitelisted(_token_address)


@internal
def _is_whitelisted(_token_address):



@external
@payable
def deposit_bounty(_token_address: address, _amount: uint256, _rate: uint256):
    """
    Todo:
    1. ensure that the deposit token is whitelisted
    2.
    """

    assert self.is_whitelisted(_token_address)
    ERC20(_token_address).transferFrom(msg.sender, self, _amount)

    self._set_reward_rate(_token_address, _rate)
    log

    pass


@internal
def _set_reward_rate(_token_address: address, _new_rate: uint256):
    """
    @notice
    @dev
    @param
    """
    assert not self.is_paused

    pass


@external
def change_reward_rate(_token_address: address, _rate: uint256):
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin

    pass


@external
def receive_bounty():
    """
    @notice
    @dev
    @param
    """
    pass


@external():
def set_oracle():
    """
    @notice
    @dev
    @param
    """
    pass


@external
def update_oracle():
    """
    @notice
    @dev
    @param
    """
    pass


@view
@external
def version() -> String[8]:
    """
    @notice Get the version of this contract
    """
    return VERSION


@external
def set_admin(_new_admin: address):
    """
    @notice Set the address allowed to mint tokens
    @dev Emits the `SetMinter` event
    @param _minter The address to set as the minter
    """
    assert msg.sender == self.admin
    self.admin = _new_admin
    log SetAdmin(msg.sender, self.admin)


@external
def pause():
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin
    self.is_paused = True


@external
def unpause():
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin
    self.is_paused = False
