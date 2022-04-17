//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {UsesTokenBase} from "../helpers/UsesTokenBase.sol";

import {Config} from "../helpers/Config.sol";
import {Empty} from "../helpers/Empty.sol";
import {MockStrategy} from "../../mocks/MockStrategy.sol";
import {TorqueVaultV1} from "@contracts/lens/vault/TorqueVaultV1.sol";

contract VaultTest is DSTest, UsesTokenBase {
    Empty private empty;
    TorqueVaultV1 private vault;
    MockStrategy private strategy;

    function setUp() public {
        empty = new Empty();

        strategy = new MockStrategy();
        strategy.initialize(Config.getToken(), Config.getInitialAPY());

        vault = new TorqueVaultV1();
        vault.initialize(Config.getToken(), strategy, address(empty), 1, 1000);

        strategy.grantRole(strategy.STRATEGY_CONTROLLER_ROLE(), address(vault));

        _fundCaller();

        address[] memory toApprove = new address[](2);
        toApprove[0] = address(strategy);
        toApprove[1] = address(vault);
        _approveAll(toApprove);
    }

    function testDepositRedeem() public {
        uint256 expectedShares = vault.previewDeposit(Config.getTokenAmount());
        vault.deposit(Config.getTokenAmount());

        assertEq(vault.balanceOf(address(this)), expectedShares);

        // **** Check that the previewed amount matches the required amount
        // **** Deposit funds into the vault
        // **** Check that the balance of the vault has been updated
        // **** Check that the recipient has more funds that what they begun with
        // **** Check that the strategy has been updated with funds
        // **** Check that the vault balance reflects the appropriate funds
        // **** Check that the redeem preview is valid
        // **** Check that the amount withdrawn is now valid
    }

    function testDepositRedeemZero() public {}

    function testDepositRedeemWithFundInjection() public {}

    function testFailDepositAllIntoStrategy() public {}

    function testDepositAllIntoStrategy() public {}
}
