// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Staking.sol";

contract NEOstake is ERC721Holder, Staking {
    using SafeERC20 for IERC20;

    // treasury wallet
    address public treasuryWallet;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(address _treasuryWallet) {
        MaxTx = 15;
        require(
            _treasuryWallet != address(0),
            "Invalid treasury wallet address"
        );
        treasuryWallet = _treasuryWallet;
    }

    /// @dev Mint/Transfer ERC20 rewards to the staker.
    function _mintRewards(
        address _rewardToken,
        address _staker,
        uint256 _rewards
    ) internal override {
        IERC20 rewardToken = IERC20(_rewardToken);
        require(
            rewardToken.allowance(treasuryWallet, address(this)) >= _rewards,
            "Insufficient allowance"
        );
        require(
            rewardToken.balanceOf(treasuryWallet) >= _rewards,
            "Insufficient balance"
        );
        transferCurrency(_rewardToken, treasuryWallet, _staker, _rewards);
    }

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }
        safeTransferERC20(_currency, _from, _to, _amount);
    }

    // @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    // Function to update the treasuryWallet address
    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(
            _newTreasuryWallet != address(0),
            "Invalid treasury wallet address"
        );
        treasuryWallet = _newTreasuryWallet;
    }

    // Receive Funds from external
    receive() external payable {
        // React to receiving ether
    }

    //////////
    // View //
    //////////

    /// @dev View available rewards for a user.
    function availableRewards(uint256 poolId, address _user)
        public
        view
        returns (uint256 _rewards)
    {
        if (stakers[poolId][_user].amountStaked == 0) {
            _rewards = stakers[poolId][_user].unclaimedRewards;
        } else {
            _rewards =
                stakers[poolId][_user].unclaimedRewards +
                _calculateRewards(poolId, _user);
        }
    }

    // Function to get staker information by pool ID and address
    function getStakerInfo(uint256 poolId, address stakerAddress) public view returns (Staker memory) {
        return stakers[poolId][stakerAddress];
    }



    /// @dev view user info
      function getUser(uint256 poolId, address _user)
        public
        view
        returns (uint256 _rewards,uint256 _staked)

    {
        _rewards = availableRewards(poolId,_user);
        _staked  = stakers[poolId][_user].amountStaked;
      
    }



    function getStakedTokens(uint256 poolId, address _user)
        public
        view
        returns (uint256[] memory)
    {
        // Check if we know this user
        if (stakers[poolId][_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
           uint256[] memory _stakedTokenIds = new uint256[](
            stakers[poolId][_user].amountStaked
            );
            uint256 _index = 0;

            for (
                uint256 j = 0;
                j < stakers[poolId][_user].stakedTokens.length;
                j++
            ) {
                if (
                    stakers[poolId][_user].stakedTokens[j].staker !=
                    (address(0))
                ) {
                _stakedTokenIds[_index] = stakers[poolId][_user].stakedTokens[j].tokenId;
                    _index++;
                }
            }
              // Resize the _stakedTokenIds array to remove any unused slots
         assembly {
            mstore(_stakedTokenIds, _index)
          }


            return _stakedTokenIds;
        }
        // Otherwise, return empty array
        else {
                  return new uint256[](0);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _stakeMsgSender()
        internal
        view
        virtual
        override
        returns (address)
    {
        return _msgSender();
    }
}