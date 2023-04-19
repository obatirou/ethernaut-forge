// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/09-King/KingFactory.sol";
import "../core/Ethernaut.sol";

contract KingTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testKingHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        KingFactory kingFactory = new KingFactory();
        ethernaut.registerLevel(kingFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(kingFactory);
        King ethernautKing = King(payable(levelAddress));

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
