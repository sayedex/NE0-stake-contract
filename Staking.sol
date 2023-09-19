// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IStaking.sol";

abstract contract Staking is IStaking, ReentrancyGuard, Ownable {
    // Mapping all pool record
    mapping(uint256 => Pool) public pools;

    //Mapping for set record if pool already made
    mapping(uint256 => bool) public activePool;

    ///@dev Mapping from condition Id to staking condition. See {struct IStaking721.StakingCondition}
    mapping(uint256 => StakingCondition) private stakingConditions;

    // Mapping of User Address to Staker info
    mapping(uint256 => mapping(address => Staker)) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => mapping(uint256 => address)) public stakerAddress;

    // Max tx limit
    uint256 public MaxTx;
    // State variable to keep track of the number of pools
    uint256 public numberOfPools;

    /*///////////////////////////////////////////////////////////////
                        External/Public Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice    Stake ERC721 Tokens.
     *
     *  @dev       See {_stake}. Override that to implement custom logic.
     *
     *  @param _tokenIds    List of tokens to stake.
     */
    function stake(uint256 poolId, uint256[] calldata _tokenIds)
        external
        nonReentrant
    {
        _stake(poolId, _tokenIds);
    }

    /**
     *  @notice    Withdraw staked tokens.
     *
     *  @dev       See {_withdraw}. Override that to implement custom logic.
     *
     *  @param _tokenIds    List of tokens to withdraw.
     */
    function withdraw(uint256 poolId, uint256[] calldata _tokenIds)
        external
        nonReentrant
    {
        _withdraw(poolId, _tokenIds);
    }

    /**
     *  @notice    Claim accumulated rewards.
     *
     *  @dev       See {_claimRewards}. Override that to implement custom logic.
     *             See {_calculateRewards} for reward-calculation logic.
     */
    function claimRewards(uint256 poolId) external nonReentrant {
        _claimRewards(poolId);
    }

    // Function to update MaxTx
    function updateMaxTx(uint256 _newMaxTx) external onlyOwner {
        require(_newMaxTx != 0, "New MaxTx must be greater than zero");
        MaxTx = _newMaxTx;
    }

    /**
     *  @notice  Set time unit. Set as a number of seconds.
     *           Could be specified as -- x * 1 hours, x * 1 days, etc.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _timeUnit    New time unit.
     */
    function setTimeUnit(uint256 poolId, uint256 _timeUnit) external onlyOwner {
        require(activePool[poolId], "Pool not exists");
        Pool storage pool = pools[poolId];
        uint256 currentId = pool.nextConditionId;
        StakingCondition memory poolConidtion = pool.stakingConditions[
            currentId - 1
        ];

        require(_timeUnit != poolConidtion.timeUnit, "Time-unit unchanged..");

        _setStakingCondition(
            poolId,
            _timeUnit,
            poolConidtion.rewardsPerUnitTime
        );

        emit UpdatedTimeUnit(poolConidtion.timeUnit, _timeUnit);
    }

    /**
     *  @notice  Set rewards per unit of time.
     *           Interpreted as x rewards per second/per day/etc based on time-unit.
     *
     *  @dev     Only admin/authorized-account can call it.
     *
     *
     *  @param _rewardsPerUnitTime    New rewards per unit time.
     */
    function setRewardsPerUnitTime(uint256 poolId, uint256 _rewardsPerUnitTime)
        external
        onlyOwner
    {   require(activePool[poolId], "Pool not exists");
        Pool storage pool = pools[poolId];
        uint256 currentId = pool.nextConditionId;
        StakingCondition memory poolConidtion = pool.stakingConditions[
            currentId - 1
        ];

        require(
            _rewardsPerUnitTime != poolConidtion.rewardsPerUnitTime,
            "Reward unchanged."
        );

        _setStakingCondition(
            poolId,
            poolConidtion.timeUnit,
            _rewardsPerUnitTime
        );

       emit UpdatedRewardsPerUnitTime(poolConidtion.rewardsPerUnitTime, _rewardsPerUnitTime);
    }

    function getTimeUnit(uint256 poolId)
        public
        view
        returns (uint256 _timeUnit)
    {   require(activePool[poolId], "Pool not exists");
        Pool storage pool = pools[poolId];
        _timeUnit = pool.stakingConditions[pool.nextConditionId - 1].timeUnit;
    }

    function getRewardsPerUnitTime(uint256 poolId)
        public
        view
        returns (uint256 _rewardsPerUnitTime)

    {    require(activePool[poolId], "Pool already exists");
        Pool storage pool = pools[poolId];
        _rewardsPerUnitTime = pool
            .stakingConditions[pool.nextConditionId - 1]
            .rewardsPerUnitTime;
    }

    // @dev get Reward amd reward time 
    
    function getPoolinfo(uint256 poolId) public view returns(uint256 _timeUnit,uint256 _rewardsPerUnitTime,uint256 _totalStaked){
         Pool storage pool = pools[poolId];
          _timeUnit = pool.stakingConditions[pool.nextConditionId - 1].timeUnit;
          _rewardsPerUnitTime = pool
            .stakingConditions[pool.nextConditionId - 1]
            .rewardsPerUnitTime;
         _totalStaked =  pool.totalStaked;  

    }

    /// @dev Set staking conditions.
    function _setStakingCondition(
        uint256 poolId,
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) internal virtual {
        require(_timeUnit != 0, "time-unit can't be 0");
        Pool storage pool = pools[poolId];

        uint256 conditionId = pool.nextConditionId;
        pool.nextConditionId += 1;

        pool.stakingConditions[conditionId] = StakingCondition({
            timeUnit: _timeUnit,
            rewardsPerUnitTime: _rewardsPerUnitTime,
            startTimestamp: block.timestamp,
            endTimestamp: 0
        });

        if (conditionId > 0) {
            pool.stakingConditions[conditionId - 1].endTimestamp = block.timestamp;
        }
    }

    // Function to add a new pool
    function addPool(
        address nftCollectionAddress,
        address rewardTokenAddress,
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) external onlyOwner {
        require(!activePool[numberOfPools], "Pool already exists");
        require(
            nftCollectionAddress != address(0) &&
                rewardTokenAddress != address(0),
            "Zero address not allowed"
        );

        Pool storage pool = pools[numberOfPools];
        pool.nftCollection = nftCollectionAddress;
        pool.rewardToken = rewardTokenAddress;
        _setStakingCondition(numberOfPools, _timeUnit, _rewardsPerUnitTime);
         activePool[numberOfPools] = true;
        numberOfPools++;
        // Emit an event to log the addition of the new pool
        emit PoolAdded(numberOfPools, nftCollectionAddress, rewardTokenAddress);
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // Increment the amountStaked and map _stakeMsgSender() to the Token Ids of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function _stake(uint256 poolId, uint256[] memory _tokenIds)
        internal
        virtual
    {
        uint256 len = _tokenIds.length;
        require(len != 0, "Staking 0 tokens");
        require(MaxTx >= len, "max limit reached");
        Pool storage pool = pools[poolId];
        address _stakingToken = pool.nftCollection;
        require(activePool[poolId], "Pool not exists");

        // If wallet has tokens staked, calculate the rewards before adding the new tokens
        if (stakers[poolId][_stakeMsgSender()].amountStaked > 0) {
            _updateUnclaimedRewardsForStaker(poolId, _stakeMsgSender());
        } else {
            stakers[poolId][_stakeMsgSender()].timeOfLastUpdate = block
                .timestamp;
            stakers[poolId][_stakeMsgSender()].conditionIdOflastUpdate =
                pool.nextConditionId -
                1;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                IERC721(_stakingToken).ownerOf(_tokenIds[i]) ==
                    _stakeMsgSender() &&
                    (IERC721(_stakingToken).getApproved(_tokenIds[i]) ==
                        address(this) ||
                        IERC721(_stakingToken).isApprovedForAll(
                            _stakeMsgSender(),
                            address(this)
                        )),
                "Not owned or approved"
            );

            // Transfer the token from the wallet to the Smart contract
            IERC721(_stakingToken).safeTransferFrom(
                _stakeMsgSender(),
                address(this),
                _tokenIds[i]
            );

            // Create StakedToken
            StakedToken memory stakedToken = StakedToken(
                _stakeMsgSender(),
                _tokenIds[i]
            );

            // Add the token to the stakedTokens array
            stakers[poolId][_stakeMsgSender()].stakedTokens.push(stakedToken);

            // Update the mapping of the tokenId to the staker's address
            stakerAddress[poolId][_tokenIds[i]] = _stakeMsgSender();
        }
        // Increment the amount staked
        stakers[poolId][_stakeMsgSender()].amountStaked += len;
        pool.totalStaked += len;

        // Update the timeOfLastUpdate for the staker
        stakers[poolId][_stakeMsgSender()].timeOfLastUpdate = block.timestamp;
        emit TokensStaked(_stakeMsgSender(), _tokenIds);
    }

    // Check if user has any ERC721 Tokens Staked and if they tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards
    // decrement the amountStaked of the user and transfer the ERC721 token back to them
    function _withdraw(uint256 poolId, uint256[] memory _tokenIds)
        internal
        virtual
    {
        Pool storage pool = pools[poolId];
        address _stakingToken = pool.nftCollection;
        require(activePool[poolId], "Pool not exists");
        uint256 _amountStaked = stakers[poolId][_stakeMsgSender()].amountStaked;
        uint256 len = _tokenIds.length;
        require(MaxTx >= len, "max limit reached");
        require(len != 0, "Withdrawing 0 tokens");
        require(_amountStaked >= len, "Withdrawing more than staked");

        // Wallet must own the token they are trying to withdraw
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakerAddress[poolId][_tokenIds[i]] == _stakeMsgSender(),
                "You don't own these tokens!"
            );
        }

        _updateUnclaimedRewardsForStaker(poolId, _stakeMsgSender());

        // Decrement the amount staked
        stakers[poolId][_stakeMsgSender()].amountStaked -= len;
        pool.totalStaked -= len;


        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Find the index of this token id in the stakedTokens array
            uint256 index = 0;
            for (
                uint256 j = 0;
                j < stakers[poolId][_stakeMsgSender()].stakedTokens.length;
                j++
            ) {
                if (
                    stakers[poolId][_stakeMsgSender()]
                        .stakedTokens[j]
                        .tokenId ==
                    _tokenIds[i] &&
                    stakers[poolId][_stakeMsgSender()].stakedTokens[j].staker !=
                    address(0)
                ) {
                    index = j;
                    break;
                }
            }

            // Set this token's .staker to be address 0 to mark it as no longer staked
            stakers[poolId][_stakeMsgSender()]
                .stakedTokens[index]
                .staker = address(0);

            // Update the mapping of the tokenId to the be address(0) to indicate that the token is no longer staked
            stakerAddress[poolId][_tokenIds[i]] = address(0);

            // Transfer the token back to the withdrawer
            IERC721(_stakingToken).safeTransferFrom(
                address(this),
                _stakeMsgSender(),
                _tokenIds[i]
            );
        }
        emit TokensWithdrawn(_stakeMsgSender(), _tokenIds);
    }

    // Calculate rewards for the _stakeMsgSender(), check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function _claimRewards(uint256 poolId) internal virtual {
        Pool storage pool = pools[poolId];
        address _rewardToken = pool.rewardToken;
        uint256 rewards = stakers[poolId][_stakeMsgSender()].unclaimedRewards +
            _calculateRewards(poolId, _stakeMsgSender());

        require(rewards != 0, "No rewards");

        stakers[poolId][_stakeMsgSender()].timeOfLastUpdate = block.timestamp;
        stakers[poolId][_stakeMsgSender()].unclaimedRewards = 0;
        stakers[poolId][_stakeMsgSender()].conditionIdOflastUpdate =
            pool.nextConditionId -
            1;
        _mintRewards(_rewardToken, _stakeMsgSender(), rewards);
        emit RewardsClaimed(_stakeMsgSender(), rewards);
    }

    /// @dev Update unclaimed rewards for a users. Called for every state change for a user.
    function _updateUnclaimedRewardsForStaker(uint256 poolId, address _staker)
        internal
        virtual
    {
        Pool storage pool = pools[poolId];
        uint256 rewards = _calculateRewards(poolId, _staker);
        stakers[poolId][_staker].unclaimedRewards += rewards;
        stakers[poolId][_staker].timeOfLastUpdate = block.timestamp;
        stakers[poolId][_staker].conditionIdOflastUpdate =
            pool.nextConditionId -
            1;
    }

    /// @dev Calculate rewards for a staker.
    function _calculateRewards(uint256 poolId, address _staker)
        internal
        view
        virtual
        returns (uint256 _rewards)
    {
        Staker memory staker = stakers[poolId][_staker];
        Pool storage pool = pools[poolId];

        uint256 _stakerConditionId = staker.conditionIdOflastUpdate;
        uint256 _nextConditionId = pool.nextConditionId;

        for (uint256 i = _stakerConditionId; i < _nextConditionId; i += 1) {
            StakingCondition memory condition = pool.stakingConditions[i];

            uint256 startTime = i != _stakerConditionId
                ? condition.startTimestamp
                : staker.timeOfLastUpdate;
            uint256 endTime = condition.endTimestamp != 0
                ? condition.endTimestamp
                : block.timestamp;

            (bool noOverflowProduct, uint256 rewardsProduct) = SafeMath.tryMul(
                (endTime - startTime) * staker.amountStaked,
                condition.rewardsPerUnitTime
            );
            (bool noOverflowSum, uint256 rewardsSum) = SafeMath.tryAdd(
                _rewards,
                rewardsProduct / condition.timeUnit
            );

            _rewards = noOverflowProduct && noOverflowSum
                ? rewardsSum
                : _rewards;
        }
    }

    /*////////////////////////////////////////////////////////////////////
        Optional hooks that can be implemented in the derived contract
    ///////////////////////////////////////////////////////////////////*/

    /// @dev Exposes the ability to override the msg sender -- support ERC2771.
    function _stakeMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    /**
     *  @dev    Mint/Transfer ERC20 rewards to the staker. Must override.
     *
     *  @param _staker    Address for which to calculated rewards.
     *  @param _rewards   Amount of tokens to be given out as reward.
     *
     *  For example, override as below to mint ERC20 rewards:
     *
     * ```
     *  function _mintRewards(address _staker, uint256 _rewards) internal override {
     *
     *      TokenERC20(rewardTokenAddress).mintTo(_staker, _rewards);
     *
     *  }
     * ```
     */
    function _mintRewards(
        address _rewardToken,
        address _staker,
        uint256 _rewards
    ) internal virtual;
}