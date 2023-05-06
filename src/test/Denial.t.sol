// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/20-Denial/DenialFactory.sol";
import "../core/Ethernaut.sol";

contract DenialTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testDenialHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        DenialFactory denialFactory = new DenialFactory();
        ethernaut.registerLevel(denialFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance{value: 0.1 ether}(denialFactory);
        Denial ethernautDenial = Denial(payable(levelAddress));

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
