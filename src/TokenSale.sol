// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeDogeElonShibMoon.sol";
import "../lib/solmate/src/utils/SafeTransferLib.sol";

contract TokenSale {
    using SafeTransferLib for SafeDogeElonShibMoon;
    // errors
    error TokenSale__PresaleHasEnded();
    error TokenSale__PublicSaleHasntStarted();
    error TokenSale__PublicSaleHasEnded();
    error TokenSale__BelowPresaleMinimumContribution();
    error TokenSale__AbovePresaleMaximumContribution();
    error TokenSale__PresaleCapReached();
    error TokenSale__InsufficientFundsForTokens();
    error TokenSale__PresaleHasntEnded();
    error TokenSale__BelowPublicSaleMinimumContribution();
    error TokenSale__AbovePublicSaleMaximumContribution();
    error TokenSale__PublicSaleCapReached();
    error TokenSale__OnlyOwnerCanDistributeTokens();
    error TokenSale__NoRefundAvailable();
    error TokenSale__NoRefundBelowPresaleMinimumContribution();
    error TokenSale__OnlyOwnerCanRaiseCap();
    error TokenSale__CanOnlyRaiseCap();

    // state variables
    SafeDogeElonShibMoon public token; // ERC-20 token being sold
    uint256 public presaleCap;
    uint256 public publicSaleCap;
    uint256 public presaleMinContribution;
    uint256 public presaleMaxContribution;
    uint256 public publicSaleMinContribution;
    uint256 public publicSaleMaxContribution;
    uint256 public constant EXHANGE_RATE = 1000; // 1 ETH = 1000 tokens (assuming 18 decimals) Hardcoded fixed rate
    uint40 public presaleEndTime;
    uint40 public publicSaleStartTime;
    uint40 public publicSaleEndTime;
    address public owner;
    mapping(address => uint256) public presaleContributions;
    mapping(address => uint256) public publicSaleContributions;

    event TokensPurchased(address indexed buyer, uint256 tokenAmount, uint256 totalContributions);
    event TokensDistributed(address indexed recipient, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    event presaleCapRaised(uint256 newCap);
    event publicSaleCapRaised(uint256 newCap);

    constructor(
        address _token,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _presaleMinContribution,
        uint256 _presaleMaxContribution,
        uint256 _publicSaleMinContribution,
        uint256 _publicSaleMaxContribution,
        uint40 _presaleDuration,
        uint40 _publicSaleDuration,
        uint40 _publicSalePreSaleInterval
    ) {
        token = SafeDogeElonShibMoon(_token);
        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        presaleMinContribution = _presaleMinContribution;
        presaleMaxContribution = _presaleMaxContribution;
        publicSaleMinContribution = _publicSaleMinContribution;
        publicSaleMaxContribution = _publicSaleMaxContribution;
        presaleEndTime = uint40(block.timestamp) + _presaleDuration;
        publicSaleStartTime = presaleEndTime + _publicSalePreSaleInterval;
        publicSaleEndTime = publicSaleStartTime + _publicSaleDuration;
        owner = msg.sender;
    }

    // Contributers can contribute to the presale
    function contributeToPresale() external payable {
        if (block.timestamp > presaleEndTime)
            revert TokenSale__PresaleHasEnded();
        if (msg.value < presaleMinContribution)
            revert TokenSale__BelowPresaleMinimumContribution();
        if (msg.value > presaleMaxContribution)
            revert TokenSale__AbovePresaleMaximumContribution();
        if (address(this).balance + msg.value > presaleCap)
            revert TokenSale__PresaleCapReached();

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        if(tokenAmount == 0)
            revert TokenSale__InsufficientFundsForTokens();

        presaleContributions[msg.sender] += msg.value;
        token.safeTransferFrom(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, tokenAmount, presaleContributions[msg.sender]);
    }

    // Contributers can contribute to the public sale
    function contributeToPublicSale() external payable {
        if (block.timestamp < publicSaleStartTime)
            revert TokenSale__PublicSaleHasntStarted();
        if(block.timestamp > publicSaleEndTime)
            revert TokenSale__PublicSaleHasEnded();
        if (msg.value < publicSaleMinContribution)
            revert TokenSale__BelowPublicSaleMinimumContribution();
        if (msg.value > publicSaleMaxContribution)
            revert TokenSale__AbovePublicSaleMaximumContribution();
        if (address(this).balance + msg.value > publicSaleCap)
            revert TokenSale__PublicSaleCapReached();

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        if (tokenAmount == 0)
            revert TokenSale__InsufficientFundsForTokens();

        publicSaleContributions[msg.sender] += msg.value;
        token.safeTransferFrom(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, tokenAmount, publicSaleContributions[msg.sender]);
    }

    // Owner can distribute tokens to specified recipient
    function distributeTokens(address recipient, uint256 amount) external {
        if (msg.sender != owner)
            revert TokenSale__OnlyOwnerCanDistributeTokens();
        token.safeTransferFrom(address(this), recipient, amount);
        emit TokensDistributed(recipient, amount);
    }

    // Contributers can claim a refund on their presale if MinContribution is not met
    function claimRefundPreSale() external {
        uint refundAmount = presaleContributions[msg.sender];
        if (presaleContributions[msg.sender] == 0)
            revert TokenSale__NoRefundAvailable();
        if (presaleContributions[msg.sender] > presaleMinContribution)
            revert TokenSale__NoRefundBelowPresaleMinimumContribution();
        presaleContributions[msg.sender] = 0;
        (bool succ, ) = payable(msg.sender).call{value: refundAmount}("");
        require(succ, "TokenSale: refund failed");
        uint256 tokenAmount = calculateTokenAmount(refundAmount);
        token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        emit RefundClaimed(msg.sender, refundAmount);
    }

    // Contributers can claim a refund on their public sale if MinContribution is not met
    function claimRefundPublicSale() external {
        uint refundAmount = publicSaleContributions[msg.sender];
        if (publicSaleContributions[msg.sender] == 0)
            revert TokenSale__NoRefundAvailable();
        if (publicSaleContributions[msg.sender] > publicSaleMinContribution)
            revert TokenSale__NoRefundBelowPresaleMinimumContribution();
        publicSaleContributions[msg.sender] = 0;
        (bool succ, ) = payable(msg.sender).call{value: refundAmount}("");
        require(succ, "TokenSale: refund failed");
        uint256 tokenAmount = calculateTokenAmount(refundAmount);
        token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        emit RefundClaimed(msg.sender, refundAmount);
    }

    // Owner can raise the presale cap
    function raisePresaleCap(uint256 newCap) external {
        if (msg.sender != owner)
            revert TokenSale__OnlyOwnerCanRaiseCap();
        if (newCap < presaleCap + 1)
            revert TokenSale__CanOnlyRaiseCap();
        presaleCap = newCap;
        emit presaleCapRaised(newCap);
    }

    // Owner can raise the public sale cap
    function raisePublicSaleCap(uint256 newCap) external {
        if (msg.sender != owner)
            revert TokenSale__OnlyOwnerCanRaiseCap();
        if (newCap < publicSaleCap + 1)
            revert TokenSale__CanOnlyRaiseCap();
        publicSaleCap = newCap;
        emit publicSaleCapRaised(newCap);
    }

    // Calculated the amount of tokens to be distributed based on the exchange rate
    function calculateTokenAmount(uint256 ethAmount) public pure returns (uint256) {
        return (ethAmount * EXHANGE_RATE) / 1e18; // Assuming 18 decimals
    }
}
