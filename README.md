
# NEO core staking contract

This README provides instructions on how to interact with the Staking smart contract. The Staking contract allows users to stake ERC721 tokens, withdraw them, and claim accumulated rewards.


## Prerequisites

Before interacting with the Staking contract, make sure you have the following:


- cas 
- Company 2





## Functions

### `setRewardsPerUnitTime`

#### Description

This function allows the owner of the contract to set the rewards per unit of time for a specific pool. It specifies the number of rewards a user earns per unit of time (e.g., per second).

#### Usage

 Make sure you are the owner of the contract.
 Call the `setRewardsPerUnitTime` function with the following parameters:
   - `poolId`: The ID of the pool you want to update.
   - `_rewardsPerUnitTime`: The new rewards per unit time value.

```solidity
function setRewardsPerUnitTime(uint256 poolId, uint256 _rewardsPerUnitTime) external onlyOwner {
    // Your code to set rewards per unit time here
}

## Used By

This project is used by the following companies:

- cas 
- Company 2


## Screenshots

[![1.png](https://i.postimg.cc/mDt15CFt/1.png)](https://postimg.cc/0M1N66ns)

