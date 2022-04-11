//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {MarginLongLiquidateCore} from "./MarginLongLiquidateCore.sol";

abstract contract MarginLongLiquidate is MarginLongLiquidateCore {
    // Helper for liquidating accounts
    function _liquidateAccount(address account_) internal {
        _resetCollateral(account_);
        _resetBorrowed(account_);
    }

    // Liquidate an account
    function liquidateAccount(address account_) external whenNotPaused returns (address[] memory, uint256[] memory) {
        require(liquidatable(account_), "MarginLongLiquidate: This account cannot be liquidated");

        (address[] memory collateralTokens, uint256[] memory collateralTax) = _taxAccount(account_, _msgSender());

        _liquidateAccount(account_);

        emit Liquidated(account_, _msgSender());

        return (collateralTokens, collateralTax);
    }
}
