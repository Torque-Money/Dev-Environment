//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Converter/IConverter.sol";
import "./LPoolApproved.sol";
import "./LPoolTax.sol";

import "hardhat/console.sol";

abstract contract LPoolDeposit is LPoolApproved, LPoolTax {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IConverter public converter;

    constructor(IConverter converter_) {
        converter = converter_;
    }

    // Set the converter to use
    function setConverter(IConverter converter_) external onlyRole(POOL_ADMIN) {
        converter = converter_;
    }

    // Get a pseudo random token from a weighted distribution of pool tokens
    function _pseudoRandomWeightedPT() internal view returns (IERC20) {
        IERC20[] memory poolTokens = _poolTokens();
        uint256[] memory weights = new uint256[](poolTokens.length);

        uint256 totalWeightSize;
        for (uint256 i = 0; i < poolTokens.length; i++) {
            (uint256 interestRateNumerator, uint256 interestRateDenominator) = interestRate(poolTokens[i]);
            uint256 _utilized = utilized(poolTokens[i]);

            uint256 weightSize = _utilized.mul(interestRateNumerator).div(interestRateDenominator).add(1);

            weights[i] = weightSize;
            totalWeightSize = totalWeightSize.add(weightSize);
        }

        uint256 randomSample = uint256(keccak256(abi.encodePacked(block.difficulty, block.number, _msgSender()))).mod(totalWeightSize);

        uint256 cumulative = 0;
        IERC20 selected;
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
    function deposit(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) {
        token_.safeTransferFrom(_msgSender(), address(this), amount_);
        IERC20 convertedToken = _pseudoRandomWeightedPT();
        uint256 convertedAmount = converter.swapMaxTokenOut(token_, amount_, convertedToken);

        uint256 totalTax = _payTax(convertedToken, convertedAmount);

        emit Deposit(_msgSender(), token_, amount_, convertedToken, convertedAmount.sub(totalTax));
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedPT(token_) {
        require(amount_ <= liquidity(token_), "LPoolDeposit: Withdraw amount exceeds available liquidity");
        token_.safeTransfer(_msgSender(), amount_);

        emit Withdraw(_msgSender(), token_, amount_);
    }

    function liquidity(IERC20 token_) public view virtual returns (uint256);

    function utilized(IERC20 token_) public view virtual returns (uint256);

    function interestRate(IERC20 token_) public view virtual returns (uint256, uint256);

    event Deposit(address indexed account, IERC20 tokenIn, uint256 amountIn, IERC20 convertedToken, uint256 convertedAmount);
    event Withdraw(address indexed account, IERC20 token, uint256 amount);
}
