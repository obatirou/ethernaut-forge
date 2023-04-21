// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/11-Elevator/ElevatorFactory.sol";
import "../core/Ethernaut.sol";

contract ElevatorTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testElevatorHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        ElevatorFactory elevatorFactory = new ElevatorFactory();
        ethernaut.registerLevel(elevatorFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(elevatorFactory);
        Elevator ethernautElevator = Elevator(payable(levelAddress));

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
