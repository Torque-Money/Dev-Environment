//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {ITaskTreasury} from "./ITaskTreasury.sol";
import {MarginLong} from "../Margin/MarginLong/MarginLong.sol";
import {IConverter} from "../Converter/IConverter.sol";

import {ResolverCore} from "./ResolverCore.sol";

abstract contract ResolverResolve is ResolverCore {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Convert liquidated amounts to ETH
    function _redepositEth(address[] memory repayToken_, uint256[] memory repayAmount_) internal returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < repayToken_.length; i++) {
            if (repayAmount_[i] > 0) {
                IERC20Upgradeable(repayToken_[i]).safeApprove(converter, repayAmount_[i]);
                uint256 amountOut = IConverter(converter).swapMaxTokenInEthOut(repayToken_[i], repayAmount_[i]);

                total = total.add(amountOut);
            }
        }

        ITaskTreasury(taskTreasury).depositFunds{value: total}(depositReceiver, ethAddress, total);

        return total;
    }

    // Check if an account needs to be liquidated
    function checkLiquidate() external view returns (bool, bytes memory) {
        address[] memory accounts = MarginLong(marginLong).getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++)
            if (MarginLong(marginLong).liquidatable(accounts[i])) return (true, abi.encodeWithSelector(this.executeLiquidate.selector, accounts[i]));

        return (false, bytes(""));
    }

    // Check if an account needs to be reset
    function checkReset() external view returns (bool, bytes memory) {
        address[] memory accounts = MarginLong(marginLong).getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++)
            if (MarginLong(marginLong).resettable(accounts[i])) return (true, abi.encodeWithSelector(this.executeReset.selector, accounts[i]));

        return (false, bytes(""));
    }

    // Execute liquidate and repay
    function executeLiquidate(address account_) external whenNotPaused {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).liquidateAccount(account_);
        _redepositEth(repayTokens, repayAmounts);
    }

    // Execute reset and repay
    function executeReset(address account_) external whenNotPaused {
        (address[] memory repayTokens, uint256[] memory repayAmounts) = MarginLong(marginLong).resetAccount(account_);
        _redepositEth(repayTokens, repayAmounts);
    }
}
