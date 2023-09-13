// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Staking.sol";

contract NEOstake is ERC721Holder, Staking {
    using SafeERC20 for IERC20;

    //reward balance
    uint256 rewardProviderTokenAllowance = 0;
    // interfaces for erc20
    IERC20 public immutable token;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(
        IERC721 _nftCollection,
        IERC20 _token,
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) {
        nftCollection = _nftCollection;
        token = _token;
        _setStakingCondition(_timeUnit, _rewardsPerUnitTime);
    }

    function addStakedTokenReward(uint256 _amount) external onlyOwner {
        //transfer from (need allowance)
        rewardProviderTokenAllowance += _amount;
        token.safeTransferFrom(_stakeMsgSender(), address(this), _amount);
    }

    function removeStakedTokenReward(uint256 _amount) external onlyOwner {
        require(
            _amount <= rewardProviderTokenAllowance,
            "you cannot withdraw this amount"
        );
        rewardProviderTokenAllowance -= _amount;
        token.safeTransfer(_stakeMsgSender(), _amount);
    }

    /// @dev Mint/Transfer ERC20 rewards to the staker.
    function _mintRewards(address _staker, uint256 _rewards) internal override {
        require(
            _rewards <= rewardProviderTokenAllowance,
            "Not enough reward tokens"
        );
        rewardProviderTokenAllowance -= _rewards;
        token.safeTransfer(_staker, _rewards);
    }

    // Receive Funds from external
    receive() external payable {
        // React to receiving ether
    }

    //////////
    // View //
    //////////

    /// @dev View available rewards for a user.
    function availableRewards(address _user)
        public
        view
        returns (uint256 _rewards)
    {
        if (stakers[_user].amountStaked == 0) {
            _rewards = stakers[_user].unclaimedRewards;
        } else {
            _rewards =
                stakers[_user].unclaimedRewards +
                _calculateRewards(_user);
        }
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    function getStakedTokens(address _user)
        public
        view
        returns (StakedToken[] memory)
    {
        // Check if we know this user
        if (stakers[_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            StakedToken[] memory _stakedTokens = new StakedToken[](
                stakers[_user].amountStaked
            );
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        // Otherwise, return empty array
        else {
            return new StakedToken[](0);
        }
    }



    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _stakeMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

}
