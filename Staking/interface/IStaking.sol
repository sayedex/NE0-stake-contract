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
