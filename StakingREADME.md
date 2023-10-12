
# NEO core staking contract

This README provides instructions on how to interact with the Staking smart contract. The Staking contract allows users to stake ERC721 tokens, withdraw them, and claim accumulated rewards.




## Prerequisites

Before interacting with the Staking contract, make sure you have the following:


- Connect to web3 wallet via polygonscan
- Must need to contract owner to call function
- open it https://polygonscan.com/address/0xb554d8F9E9c19D7F5b894471392fdbFBFA679C13#code



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


## How to update per day reward for each pool?

### POOL 0
 - poolId: The ID of the pool you want to update.
 - Pool 0
 - for example we take Genesis pool 0 , reward : 0.4/per day
 - how to calculate and call the setRewardsPerUnitTime function
 - so 0.4 per day the math will be 0.4/1440 = 0.0002777777777777778 
 - 0.0002777777777777778 is normal value we have to convert it to wei
 - visit this site and put 0.0002777777777777778 in Ether input and copy wei value https://eth-converter.com/ check it here you can convert



```solidity
function setRewardsPerUnitTime(uint256 poolId, uint256 _rewardsPerUnitTime) external onlyOwner {
  //admin
}
```  
### POOL 1
 - poolId: The ID of the pool you want to update.
 - Pool 1
 - for example we take Gold pool 1, reward : 4/per day
 - how to calculate and call the setRewardsPerUnitTime function
 - so 4 per day the math will be 4/1440 =0.002777777777777778
 - 0.002777777777777778 is normal value we have to convert it to wei
 - visit this site and put 0.002777777777777778 in Ether input and copy wei value https://eth-converter.com/ check it here you can convert



```solidity
function setRewardsPerUnitTime(uint256 poolId, uint256 _rewardsPerUnitTime) external onlyOwner {
  //admin only
}
```  

### POOL 2
 - poolId: The ID of the pool you want to update.
 - Pool 2
 - for example we take Platinum pool 2 , reward : 8/per day
 - how to calculate and call the setRewardsPerUnitTime function
 - so 8 per day the math will be 8/1440 = 0.005555555555555556
 - 0.005555555555555556 is normal value we have to convert it to wei
 - visit this site and put 0.005555555555555556 in Ether input and copy wei value https://eth-converter.com/ check it here you can convert



```solidity
function setRewardsPerUnitTime(uint256 poolId, uint256 _rewardsPerUnitTime) external onlyOwner {
  //admin 
}
``` 
### POOL 3
 - poolId: The ID of the pool you want to update.
 - Pool 3
 - for example we take Diamond pool 3 , reward : 15/per day
 - how to calculate and call the setRewardsPerUnitTime function
 - so 15 per day the math will be 15/1440 =0.010416666666666666
 - 0.010416666666666666 is normal value we have to convert it to wei
 - visit this site and put 0.010416666666666666 in Ether input and copy wei value https://eth-converter.com/ check it here you can convert



```solidity
function setRewardsPerUnitTime(uint256 poolId, uint256 _rewardsPerUnitTime) external onlyOwner {
  //admin
}
``` 

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
 - address will be staking contract address   (0xb554d8F9E9c19D7F5b894471392fdbFBFA679C13)
 - amount will be the reward you want to pay to user in total for all pool
 ![approval](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/4.png?raw=true)
