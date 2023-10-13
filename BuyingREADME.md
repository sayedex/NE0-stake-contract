
# NEO core buy NFT contract

This Solidity smart contract serves as an NFT marketplace, allowing user to buy NFTs (Non-Fungible Tokens) using the NEObux token



## Prerequisites

Before interacting with the Staking contract, make sure you have the following:


- Connect to web3 wallet via polygonscan
- Must need to contract owner to call function


## Token ID in reward token smart contract


- GENESIS 30% : 0 
- GENESIS 30% : 1
- GENESIS 30% : 2
- Diamond : 3
- Gold : 4
- Platinum : 5

## Smart Contract Functions



## 1.Set the Price of an NFT
As the owner of the contract, you have the ability to set or update the price of a listed NFT using the setNFTPrice function. This allows you to adjust the selling price of an NFT to better align with market conditions or your preferences.
- tokenId: The unique identifier of the reward NFT for which you want to set the price.
- _price: The new price (in NEObux tokens) that you wish to assign to the NFT.
-  need to put wei amount in _price
- price must be in NEObux
- use it to convert https://eth-converter.com/ 
- put the price in Ether input on  https://eth-converter.com/  then copy the wei value and paste to setNFTPrice done

```solidity

  function setNFTPrice(uint256 tokenId, uint256 _price) external onlyOwner {
        // only admin 
    }
```
### for example we set price 100 NEObux for GENESIS 30% nft  
![setprice](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/6.png?raw=true)



 

## 2.Function to update the treasuryWallet address
Keep in mind one things that is treasuryWallet need to hold all token that you want to sell otherwise contract can't sell the reward nft
- _newTreasuryWallet : new treasuryWallet address

```solidity

function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
      //admin only
}

```

 - When you update new treasuryWallet,you have to approve Buy contract in reward nft contract
 - Example call check :
 - You can find setApprovalForAll function in NEOBux contract
 - address will be Buy contract address
 - approvad - true

 ![approval](https://github.com/sayedex/NE0-stake-contract/blob/master/Screenshot/7.png?raw=true)


## 3.Function to update Disable/Enable buy function for an NFT

- tokenId: reward nft token id
- _pause: Set to true to disable the NFT or false to enable it.
```solidity
    function setNFTPause(uint256 tokenId, bool _pause) external onlyOwner {
       //admin only
    }
```

## 4.Function to Set Maximum Buy Limit for an NFT
- tokenId: reward nft token id
- _limit: The maximum quantity of the NFT that a user can purchase in one transaction.

```solidity
   function setNFTBuyLimit(uint256 tokenId, uint256 _limit)
        external
        onlyOwner
    {
     //admin only
    }
```
