// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/18-MagicNum/MagicNumFactory.sol";
import "../core/Ethernaut.sol";

contract MagicNumTest is Test {
    Ethernaut ethernaut;
    address payable attacker = payable(makeAddr("attacker"));

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testMagicNumHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        MagicNumFactory magicNumFactory = new MagicNumFactory();
        ethernaut.registerLevel(magicNumFactory);
        vm.startPrank(attacker, attacker);
        address levelAddress = ethernaut.createLevelInstance{value: 0.001 ether}(magicNumFactory);
        MagicNum ethernautMagicNum = MagicNum(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // Create a solver contract that returns 42.
        //
        // Creation code:
        // 0x69602a60005260206000f3600052600a6016f3
        // PUSH10 0x602a60005260206000f3
        // PUSH1 0x00
        // MSTORE
        // PUSH1 0x0a
        // PUSH1 0x16
        // RETURN
        //
        // runtime code:
        // 0x602a60005260206000f3
        // PUSH1 0x2a
        // PUSH1 0x00
        // MSTORE
        // PUSH1 0x20
        // PUSH1 0x00
        // RETURN
        //
        // To deploy it, we store in memory the creation code and then call CREATE.
        // We use the scratch space to store the creation code and address of the solver contract.
        // PUSH19 0x69602a60005260206000f3600052600a6016f3
        // PUSH1 0x00
        // MSTORE
        // PUSH1 0x13
        // PUSH1 0x0d
        // PUSH1 0x00
        // CREATE

        // To note:
        // the code above do not take into account the function dispatcher.
        // A solution would be to use the following code:
        // PUSH1 0x00
        // calldataload
        // PUSH1 0xE0
        // shr
        // PUSH4 0x650500c1 -> function selector of whatIsTheMeaningOfLife()
        // eq
        // iszero
        // PUSH1 0x1a
        // jumpi
        // PUSH1 0x2a
        // PUSH1 0x00
        // mstore
        // PUSH1 0x20
        // PUSH1 0x00
        // return
        // jumpdest

        address solver;
        assembly {
            mstore(0x00, 0x69602a60005260206000f3600052600a6016f3)
            solver := create(0, 0x0d, 0x13) // 0x0d = 13 bytes offset, 0x13 = 19 bytes of creation code
        }
        ethernautMagicNum.setSolver(solver);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract SolverInstance is Solver {
    function whatIsTheMeaningOfLife() public view returns (bytes32) {
        assembly {
            mstore(0x00, 0x000000000000000000000000000000000000000000000000000000000000002a)
            return(0x00, 0x20)
        }
    }
}
