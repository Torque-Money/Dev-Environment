//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/Set.sol";
import "./MarginPool.sol";

abstract contract MarginAccount is MarginPool {
    using SafeMath for uint256;
    using TokenSet for TokenSet.Set;

    struct Account {
        TokenSet.Set collateral;
        mapping(IERC20 => uint256) collateralAmounts;

        TokenSet.Set borrowed;
        mapping(IERC20 => uint256) borrowedAmounts;

        mapping(IERC20 => uint256) initialBorrowPrice;
        mapping(IERC20 => uint256) initialBorrowBlock;

        uint256 hasBorrowed;                                        // Used to check if an account is currently borrowing or not
    }

    mapping(address => Account) private _accounts;

    // Set the collateral for a given asset
    function _setCollateral(IERC20 collateral_, uint256 amount_, address account_) internal {
        Account storage account = _accounts[account_];

        if (account.collateralAmounts[collateral_] == 0 && amount_ != 0) account.collateral.insert(collateral_);
        else if (account.collateralAmounts[collateral_] != 0 && amount_ == 0) account.collateral.remove(collateral_);

        setTotalCollateral(collateral_, totalCollateral(collateral_).sub(account.collateralAmounts[collateral_]).add(amount_));
        account.collateralAmounts[collateral_] = amount_;
    }

    // Get the collateral for a given asset for a given account
    function collateral(IERC20 collateral_, address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.collateralAmounts[collateral_];
    }

    // Get the price of a token used as collateral for the asset borrowed for an account
    function collateralPrice(IERC20 collateral_, address account_) public view returns (uint256) {
        return oracle.price(collateral_, collateral(collateral_, account_));
    }

    // Get the total collateral price for a given account and asset borrowed
    function collateralPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;
        for (uint i = 0; i < account.collateral.count(); i++)
            totalPrice = totalPrice.add(collateralPrice(account.collateral.keyAtIndex(i), account_));
        return totalPrice;
    }

    // Get the collateral tokens list
    function _collateralTokens(address account_) internal view returns (IERC20[] memory) {
        return _accounts[account_].collateral.iterable();
    }

    // Set the amount the user has borrowed
    function _setBorrowed(IERC20 borrowed_, uint256 amount_, address account_) internal {
        Account storage account = _accounts[account_];

        if (account.borrowedAmounts[borrowed_] == 0 && amount_ != 0) account.borrowed.insert(borrowed_);
        else if (account.borrowedAmounts[borrowed_] != 0 && amount_ == 0) account.borrowed.remove(borrowed_);

        setTotalBorrowed(borrowed_, totalBorrowed(borrowed_).sub(account.borrowedAmounts[borrowed_]).add(amount_));
        account.hasBorrowed = account.hasBorrowed.sub(account.borrowedAmounts[borrowed_]).add(amount_);
        account.borrowedAmounts[borrowed_] = amount_;
    }

    // Get the borrowed for a given account
    function borrowed(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.borrowedAmounts[borrowed_];
    }

    // Get the current price of an asset borrowed
    function borrowedPrice(IERC20 borrowed_, address account_) public view returns (uint256) {
        return oracle.price(borrowed_, borrowed(borrowed_, account_));
    }

    // Get the total price of the assets borrowed
    function borrowedPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;
        for (uint i = 0; i < account.borrowed.count(); i++)
            totalPrice = totalPrice.add(borrowedPrice(account.borrowed.keyAtIndex(i), account_));
        return totalPrice;
    }

    // Get the borrowed tokens list
    function _borrowedTokens(address account_) internal view returns (IERC20[] memory) {
        return _accounts[account_].borrowed.iterable();
    }

    // Get the initial borrow price for an account
    function initialBorrowPrice(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialBorrowPrice[borrowed_];
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowPrice(IERC20 borrowed_, uint256 price_, address account_) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowPrice[borrowed_] = price_;
    }

    // Get the initial borrow block for an ccount
    function initialBorrowBlock(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialBorrowBlock[borrowed_];
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowBlock(IERC20 borrowed_, uint256 block_, address account_) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowBlock[borrowed_] = block_;
    }

    // Check if an account is currently borrowing
    function isBorrowing(address account_) public view returns (bool) {
        Account storage account = _accounts[account_];
        return account.hasBorrowed > 0;
    }

    // Check if an account is currently borrowing a particular asset
    function isBorrowing(IERC20 borrowed_ address account_) public view returns (bool) {
        Account storage account = _accounts[account_];
        return borrowed(borrowed_, account_) > 0;
    }
}