//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPool} from "../LPool/LPool.sol";
import {IOracle} from "../Oracle/IOracle.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {MarginPool} from "./MarginPool.sol";

abstract contract MarginAccount is MarginPool {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct Account {
        EnumerableSetUpgradeable.AddressSet collateral;
        mapping(address => uint256) collateralAmounts;
        EnumerableSetUpgradeable.AddressSet borrowed;
        mapping(address => uint256) borrowedAmounts;
        mapping(address => uint256) initialBorrowPrice;
        mapping(address => uint256) initialBorrowTime;
        mapping(address => uint256) accumulatedInterest;
        uint256 hasBorrowed;
    }

    mapping(address => Account) private _accounts;

    // Set the collateral for a given asset
    function _setCollateral(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (!account.collateral.contains(token_) && amount_ != 0) account.collateral.add(token_);
        else if (account.collateral.contains(token_) && amount_ == 0) account.collateral.remove(token_);

        _setTotalCollateral(token_, totalCollateral(token_).sub(account.collateralAmounts[token_]).add(amount_));
        account.collateralAmounts[token_] = amount_;
    }

    // Get the collateral for a given asset for a given account
    function collateral(address token_, address account_) public view onlyCollateralToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.collateralAmounts[token_];
    }

    // Get the total collateral price for a given account and asset borrowed
    function collateralPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < account.collateral.length(); i++) {
            address token = account.collateral.at(i);
            uint256 price = IOracle(oracle).priceMin(token, collateral(token, account_));

            totalPrice = totalPrice.add(price);
        }

        return totalPrice;
    }

    // Get the collateral tokens list
    function _collateralTokens(address account_) internal view returns (address[] memory) {
        return _accounts[account_].collateral.values();
    }

    // Set the amount the user has borrowed
    function _setBorrowed(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (!account.borrowed.contains(token_) && amount_ != 0) account.borrowed.add(token_);
        else if (account.borrowed.contains(token_) && amount_ == 0) account.borrowed.remove(token_);

        _setTotalBorrowed(token_, totalBorrowed(token_).sub(account.borrowedAmounts[token_]).add(amount_));
        account.hasBorrowed = account.hasBorrowed.sub(account.borrowedAmounts[token_]).add(amount_);
        account.borrowedAmounts[token_] = amount_;
    }

    // Get the borrowed for a given account
    function borrowed(address token_, address account_) public view onlyBorrowToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.borrowedAmounts[token_];
    }

    // Get the total price of the assets borrowed
    function borrowedPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < account.borrowed.length(); i++) {
            address token = account.borrowed.at(i);
            uint256 price = IOracle(oracle).priceMin(token, borrowed(token, account_));

            totalPrice = totalPrice.add(price);
        }

        return totalPrice;
    }

    // Get the borrowed tokens list
    function _borrowedTokens(address account_) internal view returns (address[] memory) {
        return _accounts[account_].borrowed.values();
    }

    // Check if an account is currently borrowing
    function _isBorrowing(address account_) internal view returns (bool) {
        Account storage account = _accounts[account_];
        return account.hasBorrowed > 0;
    }

    // Check if an account is currently borrowing a particular asset
    function _isBorrowing(address token_, address account_) internal view returns (bool) {
        return borrowed(token_, account_) > 0;
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowPrice(
        address token_,
        uint256 price_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowPrice[token_] = price_;
    }

    // Get the initial borrow price for an account
    function initialBorrowPrice(address token_, address account_) public view onlyBorrowToken(token_) returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialBorrowPrice[token_];
    }

    // Get the total initial borrow price for an account
    function initialBorrowPrice(address account_) public view returns (uint256) {
        address[] memory borrowedTokens = _borrowedTokens(account_);
        uint256 total = 0;
        for (uint256 i = 0; i < borrowedTokens.length; i++) total = total.add(initialBorrowPrice(borrowedTokens[i], account_));
        return total;
    }

    // Set the initial borrow time for an asset for an account
    function _setInitialBorrowTime(
        address token_,
        uint256 time_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowTime[token_] = time_;
    }

    // Get the initial borrow time for an asset for an account
    function _initialBorrowTime(address token_, address account_) internal view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialBorrowTime[token_];
    }

    // Set the accumulated interest
    function _setAccumulatedInterest(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.accumulatedInterest[token_] = amount_;
    }

    // Get the accumulated interest
    function _accumulatedInterest(address token_, address account_) internal view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.accumulatedInterest[token_];
    }

    // Get the interest accumulated for a given asset
    function interest(address token_, address account_) public view onlyBorrowToken(token_) returns (uint256) {
        return _accumulatedInterest(token_, account_).add(LPool(pool).interest(token_, initialBorrowPrice(token_, account_), _initialBorrowTime(token_, account_)));
    }

    // Get the interest accumulated for the total account
    function interest(address account_) public view returns (uint256) {
        address[] memory borrowedTokens = _borrowedTokens(account_);
        uint256 total = 0;
        for (uint256 i = 0; i < borrowedTokens.length; i++) total = total.add(interest(borrowedTokens[i], account_));
        return total;
    }

    // Get the total price of the account regading the value it holds
    function accountPrice(address account_) public view returns (uint256) {
        uint256 _collateralPrice = collateralPrice(account_);
        uint256 _initialBorrowPrice = initialBorrowPrice(account_);
        uint256 _borrowedPrice = borrowedPrice(account_);
        uint256 _interest = interest(account_);

        uint256 temp1 = _collateralPrice.add(_borrowedPrice);
        uint256 temp2 = _initialBorrowPrice.add(_interest);

        if (temp2 > temp1) return 0;
        return temp1.sub(temp2);
    }
}
