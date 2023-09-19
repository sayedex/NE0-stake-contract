// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTMarketplace is Ownable, ReentrancyGuard, ERC1155Holder {
    // Events
    event NftListed(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        uint256 value,
        uint256 maxLimit
    );
    event NFTPurchase(
        address indexed buyer,
        uint256 tokenId,
        uint256 amount,
        uint256 totalPrice
    );

    using SafeERC20 for IERC20;
    // Struct to represent an NFT listing
    struct Listing {
        uint256 value;
        uint256 maxLimit;
        uint256 totalBuy;
        address collectionAddress;
        bool pause;
    }

    // Reward NFT listings
    mapping(uint256 => Listing) public listings;
    // Listing record
    mapping(uint256 => bool) private isListed;
    // Mapping to keep track of how much each user has bought for each Reward NFT
    mapping(address => mapping(uint256 => uint256)) public userPurchaseAmounts;

    // NEObux token contract
    IERC20 public immutable neoBuxToken;

    // treasury wallet
    address public treasuryWallet;

    constructor(address _neoBuxToken, address _treasuryWallet) {
        neoBuxToken = IERC20(_neoBuxToken);
        treasuryWallet = _treasuryWallet;
    }

    // Function to set a collection and NFT listing
    function setCollection(
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _value,
        uint256 _maxLimit
    ) external onlyOwner {
        require(!isListed[_tokenId], "Token listed already");
        require(_value > 0, "Price can't be zero");
        Listing memory listing = Listing({
            value: _value,
            maxLimit: _maxLimit,
            totalBuy: 0,
            collectionAddress: _collectionAddress,
            pause: false
        });
        listings[_tokenId] = listing;
        isListed[_tokenId] = true;
        emit NftListed(_collectionAddress, _tokenId, _value, _maxLimit);
    }

    // Function to set the price of an NFT
    function setNFTPrice(uint256 tokenId, uint256 _price) external onlyOwner {
        require(isListed[tokenId], "Token not listed");
        Listing storage listing = listings[tokenId];
        listing.value = _price;
    }

    // Function to disable/enable the reward nft
    function setNFTPause(uint256 tokenId, bool _pause) external onlyOwner {
        require(isListed[tokenId], "Token not listed");
        Listing storage listing = listings[tokenId];
        listing.pause = _pause;
    }

    // Function to set the maximum buy limit for an NFT
    function setNFTBuyLimit(uint256 tokenId, uint256 _limit)
        external
        onlyOwner
    {
        require(isListed[tokenId], "Token not listed");
        Listing storage listing = listings[tokenId];
        listing.maxLimit = _limit;
    }

    // Function to update the treasuryWallet address
    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(
            _newTreasuryWallet != address(0),
            "Invalid treasury wallet address"
        );
        treasuryWallet = _newTreasuryWallet;
    }

    // Modifier to check if the contract has a sufficient balance
    modifier hasSufficientBalance(uint256 tokenId, uint256 amount) {
        require(isListed[tokenId], "Token not listed");
        Listing memory listing = listings[tokenId];
        require(!listing.pause, "reward nft disabled");
        require(
            listing.value * amount <= neoBuxToken.balanceOf(msg.sender),
            "Insufficient NEObux balance"
        );
        require(amount <= listing.maxLimit, "Limit exceeds");
        _;
    }

    // Function to buy an NFT
    function buyNFT(uint256 tokenId, uint256 amount)
        external
        nonReentrant
        hasSufficientBalance(tokenId, amount)
    {
        Listing storage listing = listings[tokenId];
        // Update the available quantity
        listing.totalBuy += amount;
        // Update the user's purchase amount for this NFT
        userPurchaseAmounts[msg.sender][tokenId] += amount;
        // Transfer NEObux tokens from the buyer to the contract
        safeTransferERC20(msg.sender, treasuryWallet, listing.value * amount);
        safeTransferNFT(
            listing.collectionAddress,
            treasuryWallet,
            msg.sender,
            tokenId,
            amount
        );
        // Emit the purchase event
        emit NFTPurchase(msg.sender, tokenId, amount, listing.value * amount);
    }

    // @dev Transfer `amount` of Erc1155 token from `from` to `to`.
    function safeTransferNFT(
        address _nftaddress,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }
        // Check the balance of the sender
        uint256 senderBalance = IERC1155(_nftaddress).balanceOf(
            _from,
            _tokenId
        );
        require(senderBalance >= _amount, "Insufficient balance of treasuryWallet");
        IERC1155(_nftaddress).safeTransferFrom(
            _from,
            _to,
            _tokenId,
            _amount,
            "0x"
        );
    }

    // @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            neoBuxToken.safeTransfer(_to, _amount);
        } else {
            neoBuxToken.safeTransferFrom(_from, _to, _amount);
        }
    }

    //////////
    // View //
    //////////
    // Function to get the details of a Reward NFT listing by tokenId
    function getListing(uint256 tokenId)
        external
        view
        returns (
            uint256 value,
            uint256 maxLimit,
            uint256 totalBuy,
            address collectionAddress,
            bool pause
        )
    {
        require(isListed[tokenId], "Token not listed");
        Listing memory listing = listings[tokenId];
        return (
            listing.value,
            listing.maxLimit,
            listing.totalBuy,
            listing.collectionAddress,
            listing.pause
        );
    }

    // Function to get the purchase amount for a specific user and Reward NFT
    function getUserPurchaseAmount(address user, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return userPurchaseAmounts[user][tokenId];
    }
}
