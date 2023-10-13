
# NEO core staking contract

Welcome to the NEO Core Staking Contract! This guide will walk you through the steps to stake ERC721 tokens, withdraw them, and claim accumulated rewards.





## Prerequisites

Before you get started, make sure you have the following:


- Access to a web3 wallet via PolygonScan.
- Must need to contract owner to call function
 - [Visit the contract](https://polygonscan.com/address/0xb554d8F9E9c19D7F5b894471392fdbFBFA679C13#code)



## Screenshots
- Staking contract
![Login](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/1.png?raw=true)


## Features

- Stake NFT
- Unstake NFT
- Claim reward


## Pool IDs
Each pool has its unique ID:

- Genesis : 0 
- Gold : 1
- Platinum : 2
- Diamond : 3

## Smart Contract Functions


## How to Update Daily Rewards for Each Pool?

### Pool 0 (Genesis)
  - Pool ID: 0
- Reward: 0.4 per day
 - how to calculate and call the setRewardsPerUnitTime function
 - Divide the daily reward (0.4) by the number of minutes in a day (1440).
 - so 0.4 per day the math will be 0.4/1440 = 0.0002777777777777778 
 - Convert the result to wei using this converter
 - [wei converter](https://eth-converter.com/)

  ![pool0](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/pool0.png?raw=true)




### POOL 1 (Gold)
  - Pool ID: 1
- Reward: 4 per day
 - how to calculate and call the setRewardsPerUnitTime function
 - Divide the daily reward (4) by the number of minutes in a day (1440).
 - so 4 per day the math will be 4/1440 =0.002777777777777778
 - Convert the result to wei using this converter
 - [wei converter](https://eth-converter.com/)

  ![pool1](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/pool1.png?raw=true)



 ### POOL 2 (Platinum)
  - Pool ID: 2
- Reward: 8 per day
 - how to calculate and call the setRewardsPerUnitTime function
 - Divide the daily reward (8) by the number of minutes in a day (1440).
 - so 8 per day the math will be 8/1440 = 0.005555555555555556
 - Convert the result to wei using this converter
 - [wei converter](https://eth-converter.com/)

  ![pool2](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/pool2.png?raw=true)



 ### POOL 3 (Diamond)
  - Pool ID: 3
- Reward: 15 per day
 - how to calculate and call the setRewardsPerUnitTime function
 - Divide the daily reward (15) by the number of minutes in a day (1440).
 - so 8 per day the math will be 15/1440 = 0.010416666666666666
 - Convert the result to wei using this converter
 - [wei converter](https://eth-converter.com/)

  ![pool3](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/pool3.png?raw=true)




### This function allow admin to update per transation Stake/Unstake amount limit 
- _newMaxTx : new limit
```solidity

function updateMaxTx(uint256 _newMaxTx) external onlyOwner {
     //admin only
 }

```    

## Function to update the treasuryWallet address
- _newTreasuryWallet : new treasuryWallet address
```solidity

function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
      //admin only
}

```
When you update the treasuryWallet, you need to approve NEObux tokens for the staking contract. You can find the approve function in the NEOBux contract, with the staking contract address (0xb554d8F9E9c19D7F5b894471392fdbFBFA679C13) and the reward amount you want to pay to users in total for all pools.
 - Example call check :
 ![approval](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/4.png?raw=true)
