//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {FractionMath} from "../../lib/FractionMath.sol";

import {MarginLongRepayCore} from "./MarginLongRepayCore.sol";

abstract contract MarginLongLiquidateCore is Initializable, MarginLongRepayCore {
    using FractionMath for FractionMath.Fraction;

    FractionMath.Fraction private _liquidationFeePercent;

    function initializeMarginLongLiquidateCore(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) public initializer {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Set the liquidation fee percent
    function setLiquidationFeePercent(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) external onlyRole(MARGIN_ADMIN) {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Get the liquidation fee percent
    function liquidationFeePercent() public view override returns (uint256, uint256) {
        return _liquidationFeePercent.export();
    }

    // Reset the accounts collateral
    function _resetCollateral(address account_) internal {
        address[] memory collateralTokens = _collateralTokens(account_);

        uint256[] memory collateralAmounts = new uint256[](collateralTokens.length);
        for (uint256 i = 0; i < collateralTokens.length; i++) collateralAmounts[i] = collateral(collateralTokens[i], account_);

        _deposit(collateralTokens, collateralAmounts);
        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], 0, account_);
    }

    event Liquidated(address indexed account, address executor);
}
