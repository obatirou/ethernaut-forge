// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/18-MagicNum/MagicNumFactory.sol";
import "../core/Ethernaut.sol";

contract MagicNumTest is Test {
    Ethernaut ethernaut;
    address payable attacker = payable(makeAddr("attacker"));

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testMagicNumHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        MagicNumFactory magicNumFactory = new MagicNumFactory();
        ethernaut.registerLevel(magicNumFactory);
        vm.startPrank(attacker, attacker);
        address levelAddress = ethernaut.createLevelInstance{value: 0.001 ether}(magicNumFactory);
        MagicNum ethernautMagicNum = MagicNum(payable(levelAddress));

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
