// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/16-Preservation/PreservationFactory.sol";
import "../core/Ethernaut.sol";

contract PreservationTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testPreservationHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        PreservationFactory preservationFactory = new PreservationFactory();
        ethernaut.registerLevel(preservationFactory);
        vm.startPrank(attacker, attacker); // origin has its importance in this challenge
        address levelAddress = ethernaut.createLevelInstance(preservationFactory);
        Preservation ethernautPreservation = Preservation(payable(levelAddress));

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
