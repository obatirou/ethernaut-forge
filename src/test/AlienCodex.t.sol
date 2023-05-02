// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

contract AlienCodexTest is Test {
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(attacker, 1 ether);
    }

    function testAlienCodexHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////

        // Deploy the level by hand as it is only compatible with 0.5.0 solidity version
        // The owner of AlienCodex will be the current contract (address(this))
        bytes memory bytecode = abi.encodePacked(vm.getCode("AlienCodex.sol"));
        address alienCodex;
        assembly {
            alienCodex := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        vm.startPrank(attacker);

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////

        vm.stopPrank();

        (bool success, bytes memory data) = alienCodex.call(abi.encodeWithSignature("owner()"));
        require(success, "call failed");
        address owner = abi.decode(data, (address));

        // Assert the owner of the AlienCodex contract is the attacker
        assertEq(owner, attacker);
    }
}
