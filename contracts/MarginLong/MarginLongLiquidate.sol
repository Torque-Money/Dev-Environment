//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarginLongLiquidateCore.sol";

abstract contract MarginLongLiquidate is MarginLongLiquidateCore {
    // Helper for liquidating accounts
    function _liquidateAccount(address account_) internal {
        _resetBorrowed(account_);
        _resetCollateral(account_);
    }

    // Liquidate an account
    function liquidate(address account_) internal {
        // **** I need to check that it is liquidatable first
        // **** Make sure to pay the tax first to the account
        // **** Also make sure to emit the event
    }
}
