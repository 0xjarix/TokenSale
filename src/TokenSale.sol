// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is Ownable {
    IERC20 public token; // ERC-20 token being sold
    uint256 public presaleCap;
    uint256 public publicSaleCap;
    uint256 public presaleMinContribution;
    uint256 public presaleMaxContribution;
    uint256 public publicSaleMinContribution;
    uint256 public publicSaleMaxContribution;

    uint256 public presaleEndTime;
    uint256 public publicSaleStartTime;
    uint256 public publicSaleEndTime;

    mapping(address => uint256) public presaleContributions;
    mapping(address => uint256) public publicSaleContributions;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 totalContributions);
    event TokensDistributed(address indexed recipient, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _presaleMinContribution,
        uint256 _presaleMaxContribution,
        uint256 _publicSaleMinContribution,
        uint256 _publicSaleMaxContribution,
        uint256 _presaleEndTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime
    ) {
        token = _token;
        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        presaleMinContribution = _presaleMinContribution;
        presaleMaxContribution = _presaleMaxContribution;
        publicSaleMinContribution = _publicSaleMinContribution;
        publicSaleMaxContribution = _publicSaleMaxContribution;
        presaleEndTime = _presaleEndTime;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
    }

    modifier duringPresale() {
        require(block.timestamp <= presaleEndTime, "Presale has ended");
        _;
    }

    modifier duringPublicSale() {
        require(
            block.timestamp >= publicSaleStartTime && block.timestamp <= publicSaleEndTime,
            "Public sale is not active"
        );
        _;
    }

    modifier onlyAfterPresale() {
        require(block.timestamp > presaleEndTime, "Presale is still active");
        _;
    }

    function contributeToPresale() external payable duringPresale {
        require(msg.value >= presaleMinContribution, "Below presale minimum contribution");
        require(msg.value <= presaleMaxContribution, "Exceeds presale maximum contribution");
        require(address(this).balance + msg.value <= presaleCap, "Presale cap reached");

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        require(tokenAmount > 0, "Insufficient funds for tokens");

        presaleContributions[msg.sender] += msg.value;
        token.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount, presaleContributions[msg.sender]);
    }

    function contributeToPublicSale() external payable duringPublicSale {
        require(msg.value >= publicSaleMinContribution, "Below public sale minimum contribution");
        require(msg.value <= publicSaleMaxContribution, "Exceeds public sale maximum contribution");
        require(address(this).balance + msg.value <= publicSaleCap, "Public sale cap reached");

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        require(tokenAmount > 0, "Insufficient funds for tokens");

        publicSaleContributions[msg.sender] += msg.value;
        token.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, tokenAmount, publicSaleContributions[msg.sender]);
    }

    function distributeTokens(address recipient, uint256 amount) external onlyOwner onlyAfterPresale {
        require(amount > 0, "Invalid token amount");
        token.transfer(recipient, amount);
        emit TokensDistributed(recipient, amount);
    }

    function claimRefund() external onlyAfterPresale {
        uint256 refundAmount = presaleContributions[msg.sender] + publicSaleContributions[msg.sender];
        require(refundAmount > 0, "No refund available");

        presaleContributions[msg.sender] = 0;
        publicSaleContributions[msg.sender] = 0;

        payable(msg.sender).transfer(refundAmount);

        emit RefundClaimed(msg.sender, refundAmount);
    }

    function calculateTokenAmount(uint256 ethAmount) internal view returns (uint256) {
        // Implement your token conversion logic here based on the token price
        // For simplicity, this example assumes a 1:1 conversion ratio (1 ETH = 1 Token)
        return ethAmount;
    }
}
