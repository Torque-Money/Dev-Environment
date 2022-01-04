//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Margin/Margin.sol";

abstract contract IsolatedMarginAccount is Margin {
    using SafeMath for uint256;

    struct Account {
        IERC20[] collateralTokens;
        mapping(IERC20 => uint256) indexes;
        mapping(IERC20 => uint256) collateralAmounts;

        uint256 borrowed;
        uint256 initialBorrowPrice;
        uint256 initialBorrowBlock;
    }

    mapping(IERC20 => mapping(address => Account)) private _accounts;
    mapping(IERC20 => mapping(address => uint256)) private _collateral;

    // Set the collateral for a given asset
    function _setCollateral(IERC20 borrowed_, IERC20 collateral_, uint256 amount_, address account_) internal {
        Account storage account = _accounts[borrowed_][account_];

        if (account.collateralAmounts[collateral_] == 0 && amount_ != 0) {
            account.indexes[collateral_] = account.collateralTokens.length;
            account.collateralTokens.push(collateral_);

        } else if (account.collateralAmounts[collateral_] != 0 && amount_ == 0) {
            uint256 oldIndex = account.indexes[collateral_];
            IERC20 lastToken = account.collateralTokens[account.collateralTokens.length - 1];

            account.collateralTokens[oldIndex] = lastToken;
            account.collateralTokens.pop();
            account.indexes[lastToken] = oldIndex;
        }

        account.collateralAmounts[collateral_] = amount_;
        setTotalCollateral(collateral_, totalCollateral(collateral_).sub(_collateral[borrowed_][account_]).add(amount_));
        _collateral[borrowed_][account_] = amount_;
    }

    // Get the collateral for a given asset for a given account
    function collateral(IERC20 collateral_, address account_) public view returns (uint256) {
        return _collateral[collateral_][account_];
    }

    // Get the total collateral for a given asset for a given account
    function collateral(IERC20 borrowed_, IERC20 collateral_, address account_) public view returns (uint256) {
        Account storage account = _accounts[borrowed_][account_];
        return account.collateralAmounts[collateral_];
    }

    // Get the tokens used as collateral for a given account
    function collateralTokens(IERC20 borrowed_, address account_) public view returns (IERC20[] memory) {
        Account storage account = _accounts[borrowed_][account_];
        return account.collateralTokens;
    }

    // Get the price of a token used as collateral for the asset borrowed for an account
    function collateralPrice(IERC20 borrowed_, IERC20 collateral_, address account_) public view returns (uint256) {
        Account storage account = _accounts[borrowed_][account_];
        return oracle.price(collateral_, account.collateralAmounts[collateral_]);
    }

    // Get the total collateral price for a given account and asset borrowed
    function collateralPrice(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[borrowed_][account_];
        uint256 totalPrice = 0;
        IERC20[] memory tokens = account.collateralTokens;
        for (uint i = 0; i < tokens.length; i++) {
            totalPrice = totalPrice.add(collateralPrice(borrowed_, tokens[i], account_));
        }
        return totalPrice;
    }

    // Set the amount the user has borrowed
    function _setBorrowed(IERC20 borrowed_, uint256 amount_, address account_) internal {
        Account storage account = _accounts[borrowed_][account_];

        setTotalBorrowed(borrowed_, totalBorrowed(borrowed_).sub(account.borrowed).add(amount_));
        account.borrowed = amount_;
    }

    // Get the borrowed for a given account
    function borrowed(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[borrowed_][account_];
        return account.borrowed;
    }

    // Get the total price of the assets borrowed
    function borrowedPrice(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[borrowed_][account_];
        return oracle.price(borrowed_, account.borrowed);
    }

    // Get the initial borrow price for an account
    function initialBorrowPrice(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[borrowed_][account_];
        return account.initialBorrowPrice;
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowPrice(IERC20 borrowed_, uint256 price_, address account_) internal {
        Account storage account = _accounts[borrowed_][account_];
        account.initialBorrowPrice = price_;
    }

    // Get the initial borrow block for an ccount
    function initialBorrowBlock(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[borrowed_][account_];
        return account.initialBorrowBlock;
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowBlock(IERC20 borrowed_, uint256 block_, address account_) internal {
        Account storage account = _accounts[borrowed_][account_];
        account.initialBorrowBlock = block_;
    }
}