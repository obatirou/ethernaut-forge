// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/14-GatekeeperTwo/GatekeeperTwoFactory.sol";
import "../core/Ethernaut.sol";

contract GatekeeperTwoTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testGatekeeperTwoHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        GatekeeperTwoFactory gatekeeperTwoFactory = new GatekeeperTwoFactory();
        ethernaut.registerLevel(gatekeeperTwoFactory);
        vm.startPrank(attacker, attacker); // origin has its importance in this challenge
        address levelAddress = ethernaut.createLevelInstance(gatekeeperTwoFactory);
        GatekeeperTwo ethernautGatekeeperTwo = GatekeeperTwo(payable(levelAddress));

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
