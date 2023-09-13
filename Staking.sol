// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStaking.sol";

abstract contract Staking is IStaking, ReentrancyGuard, Ownable {
    ///@dev Mapping from condition Id to staking condition. See {struct IStaking721.StakingCondition}
    mapping(uint256 => StakingCondition) private stakingConditions;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

    ///@dev Next staking condition Id. Tracks number of conditon updates so far.
    uint256 private nextConditionId;

    // total nft staked to contract
    uint256 public totalStaked = 0;

    // Interfaces for ERC721
    IERC721 public nftCollection;

    // Max tx limit
    uint256 public MaxTx;

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice    Stake ERC721 Tokens.
     *
     *  @dev       See {_stake}. Override that to implement custom logic.
     *
     *  @param _tokenIds    List of tokens to stake.
     */
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        _stake(_tokenIds);
    }

    /**
     *  @notice    Withdraw staked tokens.
     *
     *  @dev       See {_withdraw}. Override that to implement custom logic.
     *
     *  @param _tokenIds    List of tokens to withdraw.
     */
    function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
        _withdraw(_tokenIds);
    }

    /**
     *  @notice    Claim accumulated rewards.
     *
     *  @dev       See {_claimRewards}. Override that to implement custom logic.
     *             See {_calculateRewards} for reward-calculation logic.
     */
    function claimRewards() external nonReentrant {
        _claimRewards();
    }

    // Function to update MaxTx
    function updateMaxTx(uint256 _newMaxTx) external onlyOwner {
        require(_newMaxTx > 0, "New MaxTx must be greater than zero");
        MaxTx = _newMaxTx;
    }

    /**
     *  @notice  Set time unit. Set as a number of seconds.
     *           Could be specified as -- x * 1 hours, x * 1 days, etc.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _timeUnit    New time unit.
     */
    function setTimeUnit(uint256 _timeUnit) external onlyOwner {
        StakingCondition memory condition = stakingConditions[
            nextConditionId - 1
        ];
        require(_timeUnit != condition.timeUnit, "Time-unit unchanged.");

        _setStakingCondition(_timeUnit, condition.rewardsPerUnitTime);

        // emit UpdatedTimeUnit(condition.timeUnit, _timeUnit);
    }

    /**
     *  @notice  Set rewards per unit of time.
     *           Interpreted as x rewards per second/per day/etc based on time-unit.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _rewardsPerUnitTime    New rewards per unit time.
     */
    function setRewardsPerUnitTime(uint256 _rewardsPerUnitTime)
        external
        onlyOwner
    {
        StakingCondition memory condition = stakingConditions[
            nextConditionId - 1
        ];
        require(
            _rewardsPerUnitTime != condition.rewardsPerUnitTime,
            "Reward unchanged."
        );

        _setStakingCondition(condition.timeUnit, _rewardsPerUnitTime);

        // emit UpdatedRewardsPerUnitTime(condition.rewardsPerUnitTime, _rewardsPerUnitTime);
    }

    function getTimeUnit() public view returns (uint256 _timeUnit) {
        _timeUnit = stakingConditions[nextConditionId - 1].timeUnit;
    }

    function getRewardsPerUnitTime()
        public
        view
        returns (uint256 _rewardsPerUnitTime)
    {
        _rewardsPerUnitTime = stakingConditions[nextConditionId - 1]
            .rewardsPerUnitTime;
    }

    /// @dev Set staking conditions.
    function _setStakingCondition(
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) internal virtual {
        require(_timeUnit != 0, "time-unit can't be 0");
        uint256 conditionId = nextConditionId;
        nextConditionId += 1;

        stakingConditions[conditionId] = StakingCondition({
            timeUnit: _timeUnit,
            rewardsPerUnitTime: _rewardsPerUnitTime,
            startTimestamp: block.timestamp,
            endTimestamp: 0
        });

        if (conditionId > 0) {
            stakingConditions[conditionId - 1].endTimestamp = block.timestamp;
        }
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // Increment the amountStaked and map _stakeMsgSender() to the Token Ids of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function _stake(uint256[] memory _tokenIds) internal virtual {
        uint256 len = _tokenIds.length;
        require(len != 0, "Staking 0 tokens");
        require(MaxTx >= len,"max limit reached");
        // If wallet has tokens staked, calculate the rewards before adding the new tokens
        if (stakers[_stakeMsgSender()].amountStaked > 0) {
            _updateUnclaimedRewardsForStaker(_stakeMsgSender());
        } else {
            stakers[_stakeMsgSender()].timeOfLastUpdate = block.timestamp;
            stakers[_stakeMsgSender()].conditionIdOflastUpdate =
                nextConditionId -
                1;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                nftCollection.ownerOf(_tokenIds[i]) == _stakeMsgSender() &&
                    (nftCollection.getApproved(_tokenIds[i]) == address(this) ||
                        nftCollection.isApprovedForAll(
                            _stakeMsgSender(),
                            address(this)
                        )),
                "Not owned or approved"
            );

            // Transfer the token from the wallet to the Smart contract
            nftCollection.safeTransferFrom(
                _stakeMsgSender(),
                address(this),
                _tokenIds[i]
            );

            // Create StakedToken
            StakedToken memory stakedToken = StakedToken(
                _stakeMsgSender(),
                _tokenIds[i]
            );

            // Add the token to the stakedTokens array
            stakers[_stakeMsgSender()].stakedTokens.push(stakedToken);

            // Update the mapping of the tokenId to the staker's address
            stakerAddress[_tokenIds[i]] = _stakeMsgSender();
        }
        // Increment the amount staked
        stakers[_stakeMsgSender()].amountStaked += len;
        totalStaked += len;

        // Update the timeOfLastUpdate for the staker
        stakers[_stakeMsgSender()].timeOfLastUpdate = block.timestamp;
    }

    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function _withdraw(uint256[] memory _tokenIds) internal virtual {
        uint256 _amountStaked = stakers[_stakeMsgSender()].amountStaked;
        uint256 len = _tokenIds.length;
        require(MaxTx >= len,"max limit reached");
        require(len != 0, "Withdrawing 0 tokens");
        require(_amountStaked >= len, "Withdrawing more than staked");

        // Wallet must own the token they are trying to withdraw
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakerAddress[_tokenIds[i]] == _stakeMsgSender(),
                "You don't own these tokens!"
            );
        }

        _updateUnclaimedRewardsForStaker(_stakeMsgSender());

        // Decrement the amount staked
        stakers[_stakeMsgSender()].amountStaked -= len;
        totalStaked -= len;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Find the index of this token id in the stakedTokens array
            uint256 index = 0;
            for (
                uint256 j = 0;
                j < stakers[_stakeMsgSender()].stakedTokens.length;
                j++
            ) {
                if (
                    stakers[_stakeMsgSender()].stakedTokens[j].tokenId ==
                    _tokenIds[i] &&
                    stakers[_stakeMsgSender()].stakedTokens[j].staker !=
                    address(0)
                ) {
                    index = j;
                    break;
                }
            }

            // Set this token's .staker to be address 0 to mark it as no longer staked
            stakers[_stakeMsgSender()].stakedTokens[index].staker = address(0);

            // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
            stakerAddress[_tokenIds[i]] = address(0);

            // Transfer the token back to the withdrawer
            nftCollection.safeTransferFrom(
                address(this),
                _stakeMsgSender(),
                _tokenIds[i]
            );
        }
    }

    // Calculate rewards for the _stakeMsgSender(), check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function _claimRewards() internal virtual {
        uint256 rewards = stakers[_stakeMsgSender()].unclaimedRewards +
            _calculateRewards(_stakeMsgSender());

        require(rewards != 0, "No rewards");

        stakers[_stakeMsgSender()].timeOfLastUpdate = block.timestamp;
        stakers[_stakeMsgSender()].unclaimedRewards = 0;
        stakers[_stakeMsgSender()].conditionIdOflastUpdate =
            nextConditionId -
            1;
        _mintRewards(_stakeMsgSender(), rewards);
    }

    /// @dev Update unclaimed rewards for a users. Called for every state change for a user.
    function _updateUnclaimedRewardsForStaker(address _staker)
        internal
        virtual
    {
        uint256 rewards = _calculateRewards(_staker);
        stakers[_staker].unclaimedRewards += rewards;
        stakers[_staker].timeOfLastUpdate = block.timestamp;
        stakers[_staker].conditionIdOflastUpdate = nextConditionId - 1;
    }

    /// @dev Calculate rewards for a staker.
    function _calculateRewards(address _staker)
        internal
        view
        virtual
        returns (uint256 _rewards)
    {
        Staker memory staker = stakers[_staker];

        uint256 _stakerConditionId = staker.conditionIdOflastUpdate;
        uint256 _nextConditionId = nextConditionId;

        for (uint256 i = _stakerConditionId; i < _nextConditionId; i += 1) {
            StakingCondition memory condition = stakingConditions[i];

            uint256 startTime = i != _stakerConditionId
                ? condition.startTimestamp
                : staker.timeOfLastUpdate;
            uint256 endTime = condition.endTimestamp != 0
                ? condition.endTimestamp
                : block.timestamp;

            (bool noOverflowProduct, uint256 rewardsProduct) = SafeMath.tryMul(
                (endTime - startTime) * staker.amountStaked,
                condition.rewardsPerUnitTime
            );
            (bool noOverflowSum, uint256 rewardsSum) = SafeMath.tryAdd(
                _rewards,
                rewardsProduct / condition.timeUnit
            );

            _rewards = noOverflowProduct && noOverflowSum
                ? rewardsSum
                : _rewards;
        }
    }

    /*////////////////////////////////////////////////////////////////////
        Optional hooks that can be implemented in the derived contract
    ///////////////////////////////////////////////////////////////////*/

    /// @dev Exposes the ability to override the msg sender -- support ERC2771.
    function _stakeMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    /**
     *  @dev    Mint/Transfer ERC20 rewards to the staker. Must override.
     *
     *  @param _staker    Address for which to calculated rewards.
     *  @param _rewards   Amount of tokens to be given out as reward.
     *
     *  For example, override as below to mint ERC20 rewards:
     *
     * ```
     *  function _mintRewards(address _staker, uint256 _rewards) internal override {
     *
     *      TokenERC20(rewardTokenAddress).mintTo(_staker, _rewards);
     *
     *  }
     * ```
     */
    function _mintRewards(address _staker, uint256 _rewards) internal virtual;
}
