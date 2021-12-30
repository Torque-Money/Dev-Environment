//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Margin/MarginPool.sol";

abstract contract IsolatedMarginCollateral is MarginPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Account {
        IERC20[] collateralTokens;
        mapping(IERC20 => uint256) indexes;
        mapping(IERC20 => uint256) collateralAmounts;

        uint256 borrowed;
        uint256 initialBorrowPrice;
        uint256 initialBorrowBlock;
    }

    mapping(IERC20 => mapping(address => Account)) private _accounts;

    mapping(IERC20 => mapping(address => uint256)) private _borrowed;
    mapping(IERC20 => mapping(address => uint256)) private _collateral;

    // **** First I want to deal with the assets - I need a way of checking their total value and updating their indexes

    // Set the collateral for a given asset
    function _setCollateral(IERC20 borrowed_, IERC20 collateral_, uint256 amount_, address account_) internal {
        Account storage account = _accounts[borrowed_][account_];

        if (account.collateralAmounts[collateral_] == 0) {
            
        }
    }
}