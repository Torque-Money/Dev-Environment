//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../MarginLong/MarginLong.sol";
import "../LPool/LPool.sol";
import "../Converter/IConverter.sol";
import "./PokeMeReady.sol";

contract Resolver is PokeMeReady {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public converter;
    address public marginLong;
    address public pool;

    constructor(
        address pokeMe_,
        address marginLong_,
        address pool_,
        address converter_
    ) PokeMeReady(pokeMe_) {
        marginLong = marginLong_;
        pool = pool_;
        converter = converter_;
    }

    // Repay debt for eth
    function _repayInEth(
        address[] memory repayToken_,
        uint256[] memory repayAmount_,
        uint256 outAmount_
    ) internal {
        for (uint256 i = 0; i < repayToken_.length; i++) {
            uint256 amountOut = IConverter(converter).maxAmountEthOut(repayToken_[i], repayAmount_[i]);

            if (amountOut > outAmount_) {
                uint256 amountIn = IConverter(converter).minAmountTokenInEthOut(repayToken_[i], outAmount_);
                IERC20Upgradeable(repayToken_[i]).safeApprove(converter, amountIn);
                IConverter(converter).swapMaxEthOut(repayToken_[i], amountIn);
                repayAmount_[i] = repayAmount_[i].sub(amountIn);

                break;
            } else {
                IERC20Upgradeable(repayToken_[i]).safeApprove(converter, repayAmount_[i]);
                IConverter(converter).swapMaxEthOut(repayToken_[i], repayAmount_[i]);
                repayAmount_[i] = 0;
            }
        }
    }

    // Repay debt for tokens
    function _repayInToken(
        address[] memory repayToken_,
        uint256[] memory repayAmount_,
        address outToken_,
        uint256 outAmount_
    ) internal {
        for (uint256 i = 0; i < repayToken_.length; i++) {
            uint256 amountOut = IConverter(converter).maxAmountTokenOut(repayToken_[i], repayAmount_[i], outToken_);

            if (amountOut > outAmount_) {
                uint256 amountIn = IConverter(converter).minAmountTokenInTokenOut(repayToken_[i], outToken_, repayAmount_[i]);
                IERC20Upgradeable(repayToken_[i]).safeApprove(converter, amountIn);
                IConverter(converter).swapMaxTokenOut(repayToken_[i], amountIn, outToken_);
                repayAmount_[i] = repayAmount_[i].sub(amountIn);

                break;
            } else {
                IConverter(repayToken_[i]).safeApprove(converter, repayAmount_[i]);
                IConverter(converter).swapMaxTokenOut(repayToken_[i], repayAmount_[i], outToken_);
                repayAmount_[i] = 0;
            }
        }
    }

    // Pay transaction
    function _payTransaction(address[] memory repayToken_, uint256[] memory repayAmount_) internal {
        (uint256 fee, address feeToken) = IPokeMe(pokeMe).getFeeDetails();

        if (feeToken == ETH) _repayInEth(repayToken_, repayAmount_, fee);
        else _repayInToken(repayToken_, repayAmount_, feeToken, fee);

        _transfer(fee, feeToken);

        for (uint256 i = 0; i < repayToken_.length; i++) {
            if (repayAmount_[i] > 0) {
                IERC20Upgradeable(repayToken_[i]).safeApprove(pool, repayAmount_[i]);
                LPool(pool).deposit(repayToken_[i], repayAmount_[i]);
            }
        }
    }

    // Check if an account needs to be liquidated
    function checkLiquidate() external view returns (bool canExec, bytes memory execPayload) {
        address[] memory accounts = MarginLong(marginLong).getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++) {
            if (MarginLong(marginLong).liquidatable(accounts[i])) {
                canExec = true;
                execPayload = abi.encodeWithSelector(this.executeLiquidate.selector, accounts[i]);

                return (canExec, execPayload);
            }
        }

        return (false, bytes(""));
    }

    // Check if an account needs to be reset
    function checkReset() external view returns (bool canExec, bytes memory execPayload) {
        address[] memory accounts = MarginLong(marginLong).getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++) {
            if (MarginLong(marginLong).resettable(accounts[i])) {
                canExec = true;
                execPayload = abi.encodeWithSelector(this.executeReset.selector, accounts[i]);

                return (canExec, execPayload);
            }
        }

        return (false, bytes(""));
    }

    // Execute liquidate and repay
    function executeLiquidate(address account_) external onlyPokeMe {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).liquidateAccount(account_);
        _payTransaction(repayTokens, repayAmounts);
    }

    // Execute reset and repay
    function executeReset(address account_) external onlyPokeMe {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).resetAccount(account_);
        _payTransaction(repayTokens, repayAmounts);
    }
}
