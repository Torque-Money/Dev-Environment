//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../lib/FractionMath.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongLiquidateCore is Initializable, MarginLongRepayCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    FractionMath.Fraction private _liquidationFeePercent;

    function initializeMarginLongLiquidateCore(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) public initializer {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Set the liquidation fee percent
    function setLiquidationFeePercent(uint256 liquidationFeePercentNumerator_, uint256 liquidationFeePercentDenominator_) external onlyOwner {
        _liquidationFeePercent.numerator = liquidationFeePercentNumerator_;
        _liquidationFeePercent.denominator = liquidationFeePercentDenominator_;
    }

    // Get the liquidation fee percent
    function liquidationFeePercent() public view override returns (uint256, uint256) {
        return (_liquidationFeePercent.numerator, _liquidationFeePercent.denominator);
    }

    // Reset the accounts collateral
    function _resetCollateral(address account_) internal {
        address[] memory collateralTokens = _collateralTokens(account_);
        uint256[] memory collateralAmounts = _collateralAmounts(account_);

        _deposit(collateralTokens, collateralAmounts);
        for (uint256 i = 0; i < collateralTokens.length; i++) _setCollateral(collateralTokens[i], 0, account_);
    }

    event Liquidated(address indexed account, address liquidator);
}
