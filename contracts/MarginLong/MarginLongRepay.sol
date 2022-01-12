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

        emit Repay(_msgSender(), flashSwap_, data_);
    }
}
