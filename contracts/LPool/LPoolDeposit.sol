//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Converter/Converter.sol";
import "./LPoolApproved.sol";
import "./LPoolTax.sol";

abstract contract LPoolDeposit is LPoolApproved, LPoolTax {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    Converter public converter;

    constructor(Converter converter_) {
        converter = converter_;
    }

    // Set the converter to use
    function setConverter(Converter converter_) external onlyRole(POOL_ADMIN) {
        converter = converter_;
    }

    // Get a pseudo random token to convert the deposited asset to for a uniform distribution of fees
    function _pseudoRandomPT() internal view returns (IERC20) {
        IERC20[] memory tokens = _poolTokens();
        uint256 index = uint256(keccak256(abi.encodePacked(block.difficulty, block.number, _msgSender()))).mod(tokens.length);
        return tokens[index];
    }

    // Deposit a given amount of collateral into the pool and transfer a portion as a tax to the tax account
    function deposit(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) {
        token_.safeTransferFrom(_msgSender(), address(this), amount_);
        IERC20 convertedToken = _pseudoRandomPT();
        uint256 convertedAmount = converter.swapMaxOut(token_, amount_, convertedToken);

        address[] memory _taxAccounts = _taxAccounts();
        (uint256 taxPercentNumerator, uint256 taxPercentDenominator) = taxPercentage();
        uint256 tax = taxPercentNumerator.mul(convertedAmount).div(taxPercentDenominator).div(_taxAccounts.length);
        uint256 totalTax = tax.mul(_taxAccounts.length);
        for (uint256 i = 0; i < _taxAccounts.length; i++) convertedToken.safeTransfer(_taxAccounts[i], tax);

        convertedAmount = convertedAmount.sub(totalTax);
        emit Deposit(_msgSender(), token_, amount_, convertedToken, convertedAmount);
    }

    // Withdraw a given amount of collateral from the pool
    function withdraw(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyApprovedPT(token_) {
        require(amount_ <= liquidity(token_), "Withdraw amount exceeds available liquidity");
        token_.safeTransfer(_msgSender(), amount_);
        emit Withdraw(_msgSender(), token_, amount_);
    }

    function liquidity(IERC20 token_) public view virtual returns (uint256);

    event Deposit(address indexed account, IERC20 tokenIn, uint256 amountIn, IERC20 convertedToken, uint256 convertedAmount);
    event Withdraw(address indexed account, IERC20 token, uint256 amount);
}
