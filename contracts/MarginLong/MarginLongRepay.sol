//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../FlashSwap/IFlashSwap.sol";
import "./MarginLongRepayCore.sol";

abstract contract MarginLongRepay is MarginLongRepayCore {
    // Repay an account
    function repayAccount(IFlashSwap flashSwap_, bytes memory data_) external {
        _repayPayouts(_msgSender());
        _repayCollateral(_msgSender(), flashSwap_, data_);

        _removeAccount(_msgSender());

        // **** At some point here we need to add the repay tax in for the extra amounts accumulated ? (might be better to include in the margin level - look further into it)

        emit Repay(_msgSender(), flashSwap_, data_);
    }

    // **** I also want my reset account here too
}
