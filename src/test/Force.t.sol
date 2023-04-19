// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/07-Force/ForceFactory.sol";
import "../core/Ethernaut.sol";

contract ForceTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testForceHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        ForceFactory forceFactory = new ForceFactory();
        ethernaut.registerLevel(forceFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(forceFactory);
        Force ethernautForce = Force(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
