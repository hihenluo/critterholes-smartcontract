// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Lump is ERC1155, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant TOKEN_ID = 1;
    uint256 public constant MAX_SUPPLY = 100_000;
    uint256 public totalSupply;

    uint256 public bnkMintPrice;
    uint256 public ethMintPrice;

    IERC20 public bnkToken;

    address payable public bnkFeeReceiver;
    address payable public ethFeeReceiver;

    
    constructor(
        address _initialOwner,
        address _bnkTokenAddress
    ) ERC1155("") Ownable(_initialOwner) {
        bnkToken = IERC20(_bnkTokenAddress);
        
       
        bnkMintPrice = 5000;
        ethMintPrice = 650 ether;
    }

    function mintWithBNK(uint256 _amount) external nonReentrant {
        require(bnkFeeReceiver != address(0), "BNK receiver not set");
        require(_amount > 0, "Amount must be > 0");
        require(totalSupply + _amount <= MAX_SUPPLY, "Exceeds max supply");
        uint256 totalCost = bnkMintPrice * _amount;
        bnkToken.safeTransferFrom(msg.sender, bnkFeeReceiver, totalCost);
        totalSupply += _amount;
        _mint(msg.sender, TOKEN_ID, _amount, "");
    }

    function mintWithETH(uint256 _amount) external payable nonReentrant {
        require(ethFeeReceiver != address(0), "ETH receiver not set");
        require(_amount > 0, "Amount must be > 0");
        require(totalSupply + _amount <= MAX_SUPPLY, "Exceeds max supply");
        uint256 totalCost = ethMintPrice * _amount;
        require(msg.value == totalCost, "Incorrect ETH value sent");
        (bool sent, ) = ethFeeReceiver.call{value: msg.value}("");
        require(sent, "Failed to send ETH");
        totalSupply += _amount;
        _mint(msg.sender, TOKEN_ID, _amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(_id == TOKEN_ID, "Lump: invalid token ID");
        return super.uri(_id);
    }
    
    
    function setPrices(uint256 _newBnkPrice, uint256 _newEthPrice) public onlyOwner {
        bnkMintPrice = _newBnkPrice;
        ethMintPrice = _newEthPrice;
    }

    function setBnkFeeReceiver(address payable _receiver) public onlyOwner {
        require(_receiver != address(0), "Invalid address");
        bnkFeeReceiver = _receiver;
    }

    function setEthFeeReceiver(address payable _receiver) public onlyOwner {
        require(_receiver != address(0), "Invalid address");
        ethFeeReceiver = _receiver;
    }
    
    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function rescueETH() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    function rescueERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(bnkToken), "Cannot rescue BNK token");
        IERC20(_tokenAddress).safeTransfer(owner(), _amount);
    }
}