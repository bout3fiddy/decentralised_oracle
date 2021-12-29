from vyper.interfaces import ERC20


interface DecentralisedOracle:
    def owner(): -> address: view

interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def decimals() -> uint256: view
    def balanceOf(_user: address) -> uint256: view


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
    rate: uint256
    is_whitelisted: bool
    verified_depositor: address


admin: public(address)
name: public(String[32])
token_ticker: public(String[32])
bounty_tokens: HashMap[address, BountyTokenInfo]
bounty_token_id: HashMap[uint256, address]
next_bounty_token_id: uint256 = 0
DEFAULT_REWARD_RATE: uint256 = 0


@external
def __init__(_name: String[64], _token_ticker: String[32]):

    self.admin = msg.sender
    log SetAdmin(ZERO_ADDRESS, _admin)

    self.name = _name
    self.token_ticker = _token_ticker


@external
def add_bounty_token(_token_address: address, _verified_depositor_address: address, _rate: utin256):
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin
    self.bounty_tokens[_token_address] = BountyTokenInfo(
        {
            rate: _rate,
            is_whitelisted: True,
            verified_depositor: _verified_depositor_address
        }
    )
    self.bounty_token_id[self.next_bounty_token_id] = _token_address
    self.next_bounty_token_id += 1


@external
def whitelist_bounty_token(_token_address: address):
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin
    self.bounty_tokens[_token_address].is_whitelisted = True


@external
def blacklist_bounty_token(_token_address: address):
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin
    self.bounty_tokens[_token_address].is_whitelisted = False


@external
@view
def is_whitelisted(_token_address):
    """
    @notice
    @dev
    @param
    """
    return self.bounty_tokens[_token_address].is_whitelisted


@external
def change_verified_depositor(_token_address: address, _new_verified_depositor: address):
    """
    @notice The admin can change the verified depositor.
    @dev
    @param
    """
    assert msg.sender == self.admin


@external
@payable
def deposit_bounty(_token_address: address, _amount: uint256, _rate: uint256):
    """
    Todo:
    1. ensure that the deposit token is whitelisted
    2.
    """
    assert self.bounty_tokens[_token_address].is_whitelisted
    assert msg.sender == self.bounty_tokens[_token_address].verified_depositor  # only verified depositors may deposit
    assert not self.is_paused  # cannot deposit if paused

    ERC20(_token_address).transferFrom(msg.sender, self, _amount)

    log UpdateRewardRate(_token_address, self.bounty_tokens[_token_address].rate, _rate)
    self.bounty_tokens[_token_address] = _rate


@external
def set_reward_rate(_token_address: address, _new_rate: uint256):
    """
    @notice
    @dev
    @param
    """
    assert msg.sender == self.admin  # only the admin can change the reward rate

    log UpdateRewardRate(_token_address, self.bounty_tokens[_token_address].rate, _new_rate)
    self.bounty_tokens[_token_address].rate = _new_rate


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