// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/05-Token/TokenFactory.sol";
import "../core/Ethernaut.sol";

contract TokenTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testTokenHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        TokenFactory tokenFactory = new TokenFactory();
        ethernaut.registerLevel(tokenFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(tokenFactory);
        Token ethernautToken = Token(payable(levelAddress));

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
