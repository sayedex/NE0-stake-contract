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
}
