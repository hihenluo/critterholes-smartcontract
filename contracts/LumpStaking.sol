// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LumpStaking is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC1155 public immutable lumpNFT;
    IERC20 public immutable bonkToken;
    
    uint256 public constant TOKEN_ID = 1;
    uint256 public rewardRatePerDay = 250;
    uint256 public minClaimAmount = 2;

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastStakeTime;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(
        address _initialOwner,
        address _lumpNftAddress,
        address _bonkTokenAddress
    ) Ownable(_initialOwner) {
        lumpNFT = IERC1155(_lumpNftAddress);
        bonkToken = IERC20(_bonkTokenAddress);
    }

    function pendingRewards(address _user) public view returns (uint256) {
        StakeInfo storage info = stakes[_user];
        if (info.amount == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - info.lastStakeTime;
        return (info.amount * timeElapsed * rewardRatePerDay) / 86400;
    }

    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be > 0");
        _claimRewards(msg.sender);
        totalStaked += _amount;
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].lastStakeTime = block.timestamp;
        lumpNFT.safeTransferFrom(msg.sender, address(this), TOKEN_ID, _amount, "");
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        StakeInfo storage info = stakes[msg.sender];
        require(_amount > 0, "Amount must be > 0");
        require(info.amount >= _amount, "Insufficient staked amount");
        _claimRewards(msg.sender);
        totalStaked -= _amount;
        info.amount -= _amount;
        if (info.amount == 0) {
            info.lastStakeTime = 0;
        } else {
            info.lastStakeTime = block.timestamp;
        }
        lumpNFT.safeTransferFrom(address(this), msg.sender, TOKEN_ID, _amount, "");
        emit Unstaked(msg.sender, _amount);
    }
    
    function claimRewards() external nonReentrant {
        _claimRewards(msg.sender);
    }
    
    function _claimRewards(address _user) internal {
        uint256 rewards = pendingRewards(_user);
        if (rewards >= minClaimAmount) {
            require(bonkToken.balanceOf(address(this)) >= rewards, "Staking: Insufficient reward pool");
            stakes[_user].lastStakeTime = block.timestamp;
            bonkToken.safeTransfer(_user, rewards);
            emit RewardClaimed(_user, rewards);
        }
    }
    
    function setRewardRate(uint256 _newRate) public onlyOwner {
        rewardRatePerDay = _newRate;
    }

    function setMinClaimAmount(uint256 _newAmount) public onlyOwner {
        minClaimAmount = _newAmount;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function withdrawBNK(uint256 _amount) public onlyOwner {
        require(bonkToken.balanceOf(address(this)) >= _amount, "Staking: Not enough tokens to withdraw");
        bonkToken.safeTransfer(owner(), _amount);
    }
    
    function rescueETH() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    function rescueERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(bonkToken), "Cannot rescue reward token");
        IERC20(_tokenAddress).transfer(owner(), _amount);
    }
}