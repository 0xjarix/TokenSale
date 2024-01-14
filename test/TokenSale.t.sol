// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenSale} from "../src/TokenSale.sol";
import {SafeDogeElonShibMoon} from "../src/SafeDogeElonShibMoon.sol";

contract TokenSaleTest is Test {
    uint256 presaleCap = 10000 ether;
    uint256 publicSaleCap = 100000 ether;
    uint256 presaleMinContribution = 1 ether;
    uint256 presaleMaxContribution = 10 ether;
    uint256 publicSaleMinContribution = 2 ether;
    uint256 publicSaleMaxContribution = 20 ether;
    uint40 presaleDuration = 4 weeks;
    uint40 publicSaleDuration = 8 weeks;
    uint40 publicSalePreSaleInterval = 1 weeks;
    address token = address(0x1);
    TokenSale tokenSale;
    // Setup
    function setUp() public {
        vm.prank(address(this));
        tokenSale = new TokenSale(
            token,
            presaleCap,
            publicSaleCap,
            presaleMinContribution,
            presaleMaxContribution,
            publicSaleMinContribution,
            publicSaleMaxContribution,
            presaleDuration,
            publicSaleDuration,
            publicSalePreSaleInterval
        );
    }

    // Tests
    // Contributions
    /*
    function testPresaleContributionDuringPresale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 1 ether);
        (bool succ, ) = address(tokenSale).call{value: 1 ether}(abi.encodeWithSelector(tokenSale.contributeToPresale.selector));
        require(succ, "failed to contribute to presale");
        assert (tokenSale.presaleContributions(address(0x2)) == 1 ether);
        assert (SafeDogeElonShibMoon(token).balanceOf(address(0x2)) == tokenSale.calculateTokenAmount(1 ether));
    }*/

    function testPresaleContributionAfterPresale() public {
        vm.warp(block.timestamp + presaleDuration + 1);
        vm.roll(block.number + 1);
        vm.expectRevert(TokenSale.TokenSale__PresaleHasEnded.selector);
        deal(address(0x2), 2 ether);
        address(tokenSale).call{value: 1 ether}(abi.encodeWithSelector(tokenSale.contributeToPresale.selector));
    }
/*
    function testPublicSaleContributionDuringPublicSale() public {
        vm.warp(block.timestamp + presaleDuration + publicSalePreSaleInterval + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 2 ether);
        address(tokenSale).call{value: 2 ether}(abi.encodeWithSelector(tokenSale.contributeToPublicSale.selector));
        assert (tokenSale.publicSaleContributions(address(0x2)) == 2 ether);
        assert (SafeDogeElonShibMoon(token).balanceOf(address(0x2)) == tokenSale.calculateTokenAmount(2 ether));
    }
*/
    function testPublicSaleContributionAfterPublicSale() public {
        vm.warp(block.timestamp + presaleDuration + publicSalePreSaleInterval + publicSaleDuration + 1);
        vm.roll(block.number + 1); 
        vm.expectRevert(TokenSale.TokenSale__PublicSaleHasEnded.selector);
        deal(address(0x2), 2 ether);
        address(tokenSale).call{value: 2 ether}(abi.encodeWithSelector(tokenSale.contributeToPublicSale.selector));
    }

    function testPublicSaleContributionBeforePublicSale() public {
        vm.warp(block.timestamp + presaleDuration + 1);
        vm.roll(block.number + 1);
        vm.expectRevert(TokenSale.TokenSale__PublicSaleHasntStarted.selector);
        deal(address(0x2), 2 ether);
        address(tokenSale).call{value: 2 ether}(abi.encodeWithSelector(tokenSale.contributeToPublicSale.selector));
    }

    function testPresaleContributionBelowMinContribution() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 1 ether);
        vm.expectRevert(TokenSale.TokenSale__BelowPresaleMinimumContribution.selector);
        address(tokenSale).call{value: 10**17}(abi.encodeWithSelector(tokenSale.contributeToPresale.selector));
    }
    function testPublicSaleContributionBelowMinContribution() public {
        vm.warp(block.timestamp + presaleDuration + publicSalePreSaleInterval + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 1 ether);
        vm.expectRevert(TokenSale.TokenSale__BelowPublicSaleMinimumContribution.selector);
        address(tokenSale).call{value: 1 ether}(abi.encodeWithSelector(tokenSale.contributeToPublicSale.selector));
    }
    function testPresaleContributionAboveMaxContribution() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 11 ether);
        vm.expectRevert(TokenSale.TokenSale__AbovePresaleMaximumContribution.selector);
        address(tokenSale).call{value: 11 ether}(abi.encodeWithSelector(tokenSale.contributeToPresale.selector));
    }
    function testPublicSaleContributionAboveMaxContribution() public {
        vm.warp(block.timestamp + presaleDuration + publicSalePreSaleInterval + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 21 ether);
        vm.expectRevert(TokenSale.TokenSale__AbovePublicSaleMaximumContribution.selector);
        address(tokenSale).call{value: 21 ether}(abi.encodeWithSelector(tokenSale.contributeToPublicSale.selector));
    }

    function testPublicSaleContributionCap() public {
        vm.warp(block.timestamp + presaleDuration + publicSalePreSaleInterval + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 50000 ether);
        address(tokenSale).call{value: 50000 ether}(abi.encodeWithSelector(tokenSale.contributeToPublicSale.selector));
        deal(address(0x3), 50001 ether);
        vm.expectRevert(TokenSale.TokenSale__PublicSaleCapReached.selector);
        address(tokenSale).call{value: 50001 ether}(abi.encodeWithSelector(tokenSale.contributeToPublicSale.selector));
    }
    /*
    function testPresaleContributionCap() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        deal(address(0x2), 5000 ether);
        (bool succ,) = address(tokenSale).call{value: 5000 ether}(abi.encodeWithSelector(tokenSale.contributeToPresale.selector));
        require(succ, "contribution failed");
        deal(address(0x3), 5001 ether);
        vm.expectRevert(TokenSale.TokenSale__PresaleCapReached.selector);
        address(tokenSale).call{value: 5001 ether}(abi.encodeWithSelector(tokenSale.contributeToPresale.selector));
    }

    // Token Distribution
    function testDistributeTokens() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        address alice = makeAddr("alice");
        deal(address(this), 1 ether);
        tokenSale.distributeTokens(alice, 100000000);
        assert (SafeDogeElonShibMoon(token).balanceOf(alice) == tokenSale.calculateTokenAmount(100000000));
    }

    function testDistributeTokensByNonOwner() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        address alice = makeAddr("alice");
        deal(address(0x2), 1 ether);
        vm.expectRevert(TokenSale.TokenSale__OnlyOwnerCanDistributeTokens.selector);
        tokenSale.distributeTokens(alice, 100000000);
        assert (SafeDogeElonShibMoon(token).balanceOf(alice) == tokenSale.calculateTokenAmount(100000000));
    }
    // Refunds
    /*
    function testClaimRefundPresale() public {

    }

    function testClaimRefundPublicSale() public {

    }

    function testClaimRefundPresaleNoContribution() public {

    }

    function testClaimRefundPublicSaleNoContribution() public {

    }

    function testClaimRefundPresaleContributedTooMuch() public {

    }

    function testClaimRefundPublicSaleContributedTooMuch() public {

    }

    function testRaiseCapPresale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(this));
        tokenSale.raisePresaleCap(1000000);
        assert(tokenSale.presaleCap() == 1000000);
    }
    function testRaiseCapPublicSale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(this));
        tokenSale.raisePublicSaleCap(100000);
        assert(tokenSale.publicSaleCap() == 100000);
    }*/

    function testRaiseCapByNotOwnerPresale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(0x4));
        vm.expectRevert(TokenSale.TokenSale__OnlyOwnerCanRaiseCap.selector);
        tokenSale.raisePresaleCap(100000000);
    }

    function testRaiseCapByNotOwnerPublicSale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(0x4));
        vm.expectRevert(TokenSale.TokenSale__OnlyOwnerCanRaiseCap.selector);
        tokenSale.raisePublicSaleCap(100000000);
    }

    function testRaiseCapWithLessCapPresale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(this));
        vm.expectRevert(TokenSale.TokenSale__CanOnlyRaiseCap.selector);
        tokenSale.raisePresaleCap(1);
    }

    function testRaiseCapWithLessCapPublicSale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(this));
        vm.expectRevert(TokenSale.TokenSale__CanOnlyRaiseCap.selector);
        tokenSale.raisePublicSaleCap(10);
    }

    function testRaiseCapWithSameCapPresale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(this));
        vm.expectRevert(TokenSale.TokenSale__CanOnlyRaiseCap.selector);
        tokenSale.raisePublicSaleCap(10000);
    }

    function testRaiseCapWithSameCapPublicSale() public {
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        vm.prank(address(this));
        vm.expectRevert(TokenSale.TokenSale__CanOnlyRaiseCap.selector);
        tokenSale.raisePublicSaleCap(100000);
    }
}
