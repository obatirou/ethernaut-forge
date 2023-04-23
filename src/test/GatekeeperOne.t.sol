// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/13-GatekeeperOne/GatekeeperOneFactory.sol";
import "../core/Ethernaut.sol";

contract GatekeeperOneTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testGatekeeperOneHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        GatekeeperOneFactory gatekeeperOneFactory = new GatekeeperOneFactory();
        ethernaut.registerLevel(gatekeeperOneFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(gatekeeperOneFactory);
        GatekeeperOne ethernautGatekeeperOne = GatekeeperOne(payable(levelAddress));

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
