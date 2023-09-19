
# NEO core staking contract

This README provides instructions on how to interact with the Staking smart contract. The Staking contract allows users to stake ERC721 tokens, withdraw them, and claim accumulated rewards.




## Prerequisites

Before interacting with the Staking contract, make sure you have the following:


- Connect to web3 wallet via polygonscan
- Must need to contract owner to call function



## Screenshots
- Staking contract
![Login](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/1.png?raw=true)


## Features

- Stake NFT
- Unstake NFT
- Claim reward


## Pool id 



- Genesis : 0 
- Gold : 1
- Platinum : 2
- Diamond : 3

## Smart Contract Functions



### This function will allow admin to update new reward to contract
 - poolId: The ID of the pool you want to update.
 -  it's per minute reward. for example if you put 0.69 token reward will be 994 per day so the logic is like in 24h there are 1440 minute so if you put 0.69 token reward will be 0.69*1440 = 994
 -  _rewardsPerUnitTime: The new rewards per unit time value.  https://eth-converter.com/ check it here you can convert



```solidity
function setRewardsPerUnitTime(uint256 poolId, uint256 _rewardsPerUnitTime) external onlyOwner {
  //admin only
}
```


![SetReward](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/3.png?raw=true)
- NEOBux to Wei
- NEOBux token to wei value, for example 100 NEOBux means 100000000000000000000 wei

![Wei convert](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/5.png?raw=true)   





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

 - When you update new treasuryWallet,you have to approve NEObux token for staking contract
 - Example call check :
 - You can find approve function in NEOBux contract
 - address will be staking contract address
 - amount will be the reward you want to pay to user in total for all pool
 ![approval](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/4.png?raw=true)
