//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../Oracle/IOracle.sol";
import "../Converter/IConverter.sol";
import "./LPoolApproved.sol";
import "./LPoolTax.sol";

abstract contract LPoolDeposit is LPoolApproved, LPoolTax {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Get a pseudo random token from a weighted distribution of pool tokens
    function _pseudoRandomWeightedPT() internal view returns (address) {
        address[] memory poolTokens = _poolTokens();
        uint256[] memory weights = new uint256[](poolTokens.length);

        uint256 totalWeightSize;
        for (uint256 i = 0; i < poolTokens.length; i++) {
            (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(poolTokens[i]);
            uint256 _utilized = IOracle(oracle).priceMax(poolTokens[i], utilized(poolTokens[i]));

            uint256 weightSize = _utilized.mul(interestRateNumerator).div(interestRateDenominator).add(1);

            weights[i] = weightSize;
            totalWeightSize = totalWeightSize.add(weightSize);
        }

        uint256 randomSample = uint256(keccak256(abi.encodePacked(block.difficulty, block.number, gasleft(), _msgSender()))).mod(totalWeightSize);

        uint256 cumulative = 0;
        address selected;
        for (uint256 i = 0; i < poolTokens.length; i++) {
            cumulative = cumulative.add(weights[i]);
            if (randomSample <= cumulative) {
                selected = poolTokens[i];
                break;
            }
        }
        return selected;
    }

    // Deposit a given amount of collateral into the pool and transfer a portion as a tax to the tax account
    function deposit(address token_, uint256 amount_) external onlyRole(POOL_APPROVED) {
        require(amount_ > 0, "LPoolDeposit: Deposit amount must be greater than 0");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);

        address convertedToken = _pseudoRandomWeightedPT();
        uint256 convertedAmount = amount_;
        if (convertedToken != token_) {
            IERC20Upgradeable(token_).safeApprove(converter, amount_);
            convertedAmount = IConverter(converter).swapMaxTokenOut(token_, amount_, convertedToken);
        }

        uint256 totalTax = _payTax(convertedToken, convertedAmount);

        emit Deposit(_msgSender(), token_, amount_, convertedToken, convertedAmount.sub(totalTax));
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(address token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedPT(token_) {
        require(amount_ > 0, "LPoolDeposit: Withdraw amount must be greater than 0");
        require(amount_ <= liquidity(token_), "LPoolDeposit: Withdraw amount exceeds available liquidity");

        IERC20Upgradeable(token_).safeTransfer(_msgSender(), amount_);

        emit Withdraw(_msgSender(), token_, amount_);
    }

    function liquidity(address token_) public view virtual returns (uint256);

    function utilized(address token_) public view virtual returns (uint256);

    function interestRate(address token_) public view virtual returns (uint256, uint256);

    event Deposit(address indexed account, address tokenIn, uint256 amountIn, address convertedToken, uint256 convertedAmount);
    event Withdraw(address indexed account, address token, uint256 amount);
}
