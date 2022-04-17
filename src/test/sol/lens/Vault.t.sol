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
        vault.grantRole(vault.VAULT_CONTROLLER_ROLE(), address(this));

        _fundCaller();

        address[] memory toApprove = new address[](2);
        toApprove[0] = address(strategy);
        toApprove[1] = address(vault);
        _approveAll(toApprove);
    }

    function testDepositRedeem() public {
        IERC20[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        // Check that the previewed shares matches the allocated shares
        uint256 expectedShares = vault.previewDeposit(tokenAmount);
        vault.deposit(tokenAmount);

        assertEq(vault.balanceOf(address(this)), expectedShares);

        // Check that vault has been allocated the correct amount of tokens
        for (uint256 i = 0; i < token.length; i++) assertEq(vault.balance(token[i]), tokenAmount[i]);

        // Check that the vault balance reflects the appropriate funds
        vault.withdrawAllFromStrategy();

        for (uint256 i = 0; i < token.length; i++) assertEq(token[i].balanceOf(address(vault)), tokenAmount[i]);

        // Check that the redeem preview matches the amount allocated

        // Check the the correct shares are burned
    }

    // function testDepositRedeemZero() public {}

    // function testDepositRedeemWithFundInjection() public {}

    // function testFailDepositAllIntoStrategy() public {}

    // function testDepositAllIntoStrategy() public {}
}
