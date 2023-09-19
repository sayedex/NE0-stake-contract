// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStaking {
    /**
     *  @notice Staking Condition.
     *
     *  @param timeUnit           Unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.
     *
     *  @param rewardsPerUnitTime Rewards accumulated per unit of time.
     *
     *  @param startTimestamp     Condition start timestamp.
     *
     *  @param endTimestamp       Condition end timestamp.
     */
    struct StakingCondition {
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    // Define a Pool struct
    struct Pool {
        uint256 nextConditionId;
        mapping(uint256 => StakingCondition) stakingConditions;
        address nftCollection;
        address rewardToken;
        uint256 totalStaked;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }

    // Staker info
    struct Staker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;
        // Staked token ids
        StakedToken[] stakedTokens;
        // Last time of the rewards were calculated for this user
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
        uint256 conditionIdOflastUpdate;
    }
    /// @dev Emitted when a pool created
    event PoolAdded(
        uint256 indexed poolId,
        address indexed nftCollectionAddress,
        address indexed rewardTokenAddress
    );
    /// @dev Emitted when a set of token-ids are staked.
    event TokensStaked(address indexed staker, uint256[] indexed tokenIds);

    /// @dev Emitted when a set of staked token-ids are withdrawn.
    event TokensWithdrawn(address indexed staker, uint256[] indexed tokenIds);

    /// @dev Emitted when a staker claims staking rewards.
    event RewardsClaimed(address indexed staker, uint256 rewardAmount);

    /// @dev Emitted when contract admin updates timeUnit.
    event UpdatedTimeUnit(uint256 oldTimeUnit, uint256 newTimeUnit);

    /// @dev Emitted when contract admin updates rewardsPerUnitTime.
    event UpdatedRewardsPerUnitTime(
        uint256 oldRewardsPerUnitTime,
        uint256 newRewardsPerUnitTime
    );
}