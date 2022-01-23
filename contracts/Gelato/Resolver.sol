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

    // Repay debt for eth
    function _repayInEth(
        IERC20[] memory repayToken_,
        uint256[] memory repayAmount_,
        uint256 outAmount_
    ) internal {
        for (uint256 i = 0; i < repayToken_.length; i++) {
            uint256 amountOut = converter.maxAmountEthOut(repayToken_[i], repayAmount_[i]);

            if (amountOut > outAmount_) {
                uint256 amountIn = converter.minAmountTokenInEthOut(repayToken_[i], outAmount_);
                repayToken_[i].safeApprove(address(converter), amountIn);
                converter.swapMaxEthOut(repayToken_[i], amountIn);
                repayAmount_[i] = repayAmount_[i].sub(amountIn);
                break;
            } else {
                repayToken_[i].safeApprove(address(converter), repayAmount_[i]);
                converter.swapMaxEthOut(repayToken_[i], repayAmount_[i]);
                repayAmount_[i] = 0;
            }
        }
    }

    // Repay debt for tokens
    function _repayInToken(
        IERC20[] memory repayToken_,
        uint256[] memory repayAmount_,
        IERC20 outToken_,
        uint256 outAmount_
    ) internal {
        for (uint256 i = 0; i < repayToken_.length; i++) {
            uint256 amountOut = converter.maxAmountTokenOut(repayToken_[i], repayAmount_[i], outToken_);

            if (amountOut > outAmount_) {
                uint256 amountIn = converter.minAmountTokenInTokenOut(repayToken_[i], outToken_, repayAmount_[i]);
                repayToken_[i].safeApprove(address(converter), amountIn);
                converter.swapMaxTokenOut(repayToken_[i], amountIn, outToken_);
                repayAmount_[i] = repayAmount_[i].sub(amountIn);
                break;
            } else {
                repayToken_[i].safeApprove(address(converter), repayAmount_[i]);
                converter.swapMaxTokenOut(repayToken_[i], repayAmount_[i], outToken_);
                repayAmount_[i] = 0;
            }
        }
    }

    // Pay transaction
    function _payTransaction(IERC20[] memory repayToken_, uint256[] memory repayAmount_) internal {
        (uint256 fee, address feeToken) = IPokeMe(pokeMe).getFeeDetails();

        if (feeToken == ETH) _repayInEth(repayToken_, repayAmount_, fee);
        else _repayInToken(repayToken_, repayAmount_, IERC20(feeToken), fee);

        _transfer(fee, feeToken);

        for (uint256 i = 0; i < repayToken_.length; i++) {
            if (repayAmount_[i] > 0) {
                repayToken_[i].safeApprove(address(pool), repayAmount_[i]);
                pool.deposit(repayToken_[i], repayAmount_[i]);
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
