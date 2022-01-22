//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../MarginLong/MarginLong.sol";
import "../LPool/LPool.sol";
import "../Converter/IConverter.sol";
import "./PokeMeReady.sol";

contract Resolver is PokeMeReady {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    MarginLong public marginLong;
    LPool public pool;
    IConverter public converter;

    constructor(
        address pokeMe_,
        MarginLong marginLong_,
        LPool pool_,
        IConverter converter_
    ) PokeMeReady(pokeMe_) {
        marginLong = marginLong_;
        pool = pool_;
        converter = converter_;
    }

    // Pay transaction
    function _payTransaction(IERC20[] memory repayTokens_, uint256[] memory repayAmounts_) internal {
        (uint256 fee, address feeToken) = IPokeMe(pokeMe).getFeeDetails();

        for (uint256 i = 0; i < repayTokens_.length; i++) {
            uint256 amountOut = converter.maxAmountOut(repayTokens_[i], repayAmounts_[i], IERC20(feeToken));

            if (amountOut > fee) {
                uint256 amountIn = converter.minAmountIn(repayTokens_[i], IERC20(feeToken), repayAmounts_[i]);
                repayTokens_[i].safeApprove(address(converter), amountIn);
                converter.swapMaxOut(repayTokens_[i], amountIn, IERC20(feeToken));
                repayAmounts_[i] = repayAmounts_[i].sub(amountIn);
                break;
            } else {
                repayTokens_[i].safeApprove(address(converter), repayAmounts_[i]);
                converter.swapMaxOut(repayTokens_[i], repayAmounts_[i], IERC20(feeToken));
                repayAmounts_[i] = 0;
            }
        }

        _transfer(fee, feeToken);

        for (uint256 i = 0; i < repayTokens_.length; i++) {
            if (repayAmounts_[i] > 0) {
                repayTokens_[i].safeApprove(address(pool), repayAmounts_[i]);
                pool.deposit(repayTokens_[i], repayAmounts_[i]);
            }
        }
    }

    // Check if an account needs to be liquidated
    function checkLiquidate() external view returns (bool canExec, bytes memory execPayload) {
        address[] memory accounts = marginLong.getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++) {
            if (marginLong.liquidatable(accounts[i])) {
                canExec = true;
                execPayload = abi.encodeWithSelector(this.executeLiquidate.selector, accounts[i]);

                return (canExec, execPayload);
            }
        }

        return (false, bytes(""));
    }

    // Check if an account needs to be reset
    function checkReset() external view returns (bool canExec, bytes memory execPayload) {
        address[] memory accounts = marginLong.getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++) {
            if (marginLong.resettable(accounts[i])) {
                canExec = true;
                execPayload = abi.encodeWithSelector(this.executeReset.selector, accounts[i]);

                return (canExec, execPayload);
            }
        }

        return (false, bytes(""));
    }

    // Execute liquidate and repay
    function executeLiquidate(address account_) external onlyPokeMe {
        (IERC20[] memory repayTokens, uint256[] memory repayAmounts) = marginLong.liquidateAccount(account_);
        _payTransaction(repayTokens, repayAmounts);
    }

    // Execute reset and repay
    function executeReset(address account_) external onlyPokeMe {
        (IERC20[] memory repayTokens, uint256[] memory repayAmounts) = marginLong.resetAccount(account_);
        _payTransaction(repayTokens, repayAmounts);
    }
}
