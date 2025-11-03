// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IBONK is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

contract Swap is Ownable, ReentrancyGuard {
    IBONK public immutable bonkToken;
    uint256 public rate;
    uint256 public minSwap;

    event Swapped(address indexed user, uint256 bonkBurned, uint256 ethReceived);
    event RateUpdated(uint256 newRate);

    constructor(
        address _initialOwner,
        address _bonkTokenAddress
    ) Ownable(_initialOwner) {
        bonkToken = IBONK(_bonkTokenAddress);
        rate = 10;
        minSwap = 100;
    }

    receive() external payable {}

    function swap (uint256 _bonkAmount) external nonReentrant {
        require(_bonkAmount >= minSwap, "Swap: Amount is below minimum");

        uint256 ethAmount = (_bonkAmount * 1 ether) / rate;
        require(address(this).balance >= ethAmount, "Swap: Insufficient ETH liquidity");

        bonkToken.burnFrom(msg.sender, _bonkAmount);

        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        require(sent, "Swap: Failed to send ETH");

        emit Swapped(msg.sender, _bonkAmount, ethAmount);
    }

    function setRate(uint256 _newrate) public onlyOwner {
        require(_newrate > 0, "Rate must be > 0");
        rate = _newrate;
        emit RateUpdated(_newrate);
    }

    function setMinSwap(uint256 _newMinAmount) public onlyOwner {
        minSwap = _newMinAmount;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        (bool sent, ) = owner().call{value: _amount}("");
        require(sent, "Withdraw: Failed to send ETH");
    }
    
    function rescueERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(bonkToken), "Cannot rescue BONK token");
        IERC20(_tokenAddress).transfer(owner(), _amount);
    }
}