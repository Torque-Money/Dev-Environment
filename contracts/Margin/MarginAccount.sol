//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/Set.sol";
import "./MarginPool.sol";

import "hardhat/console.sol";

abstract contract MarginAccount is MarginPool {
    using SafeMath for uint256;
    using Set for Set.TokenSet;

    struct Account {
        Set.TokenSet collateral;
        mapping(IERC20 => uint256) collateralAmounts;
        Set.TokenSet borrowed;
        mapping(IERC20 => uint256) borrowedAmounts;
        mapping(IERC20 => uint256) initialBorrowPrice;
        mapping(IERC20 => uint256) initialBorrowBlock;
        uint256 hasBorrowed;
    }

    mapping(address => Account) private _accounts;

    // Set the collateral for a given asset
    function _setCollateral(
        IERC20 collateral_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (account.collateralAmounts[collateral_] == 0 && amount_ != 0) account.collateral.insert(collateral_);
        else if (account.collateralAmounts[collateral_] != 0 && amount_ == 0) account.collateral.remove(collateral_);

        _setTotalCollateral(collateral_, totalCollateral(collateral_).sub(account.collateralAmounts[collateral_]).add(amount_));
        account.collateralAmounts[collateral_] = amount_;
    }

    // Get the collateral for a given asset for a given account
    function collateral(IERC20 collateral_, address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.collateralAmounts[collateral_];
    }

    // Get the price of a token used as collateral for the asset borrowed for an account
    function _collateralPrice(IERC20 collateral_, address account_) internal view returns (uint256) {
        return oracle.priceMin(collateral_, collateral(collateral_, account_));
    }

    // Get the total collateral price for a given account and asset borrowed
    function collateralPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < account.collateral.count(); i++) totalPrice = totalPrice.add(_collateralPrice(account.collateral.keyAtIndex(i), account_));
        return totalPrice;
    }

    // Get the collateral tokens list
    function _collateralTokens(address account_) internal view returns (IERC20[] memory) {
        return _accounts[account_].collateral.iterable();
    }

    // Get the amount of each collateral token
    function _collateralAmounts(address account_) internal view returns (uint256[] memory) {
        IERC20[] memory tokens = _collateralTokens(account_);
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) amounts[i] = collateral(tokens[i], account_);
        return amounts;
    }

    // Set the amount the user has borrowed
    function _setBorrowed(
        IERC20 borrowed_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (account.borrowedAmounts[borrowed_] == 0 && amount_ != 0) account.borrowed.insert(borrowed_);
        else if (account.borrowedAmounts[borrowed_] != 0 && amount_ == 0) account.borrowed.remove(borrowed_);

        _setTotalBorrowed(borrowed_, totalBorrowed(borrowed_).sub(account.borrowedAmounts[borrowed_]).add(amount_));
        account.hasBorrowed = account.hasBorrowed.sub(account.borrowedAmounts[borrowed_]).add(amount_);
        account.borrowedAmounts[borrowed_] = amount_;

        console.log("Set borrowed");
        console.log(address(borrowed_));
        console.log(account_);
        console.log(account.hasBorrowed);
        console.log("");
    }

    // Get the borrowed for a given account
    function borrowed(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.borrowedAmounts[borrowed_];
    }

    // Get the current price of an asset borrowed
    function _borrowedPrice(IERC20 borrowed_, address account_) internal view returns (uint256) {
        return oracle.priceMin(borrowed_, borrowed(borrowed_, account_));
    }

    // Get the total price of the assets borrowed
    function borrowedPrice(address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < account.borrowed.count(); i++) totalPrice = totalPrice.add(_borrowedPrice(account.borrowed.keyAtIndex(i), account_));
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

    // Get the total initial borrow price for an account
    function initialBorrowPrice(address account_) public view returns (uint256) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256 total = 0;
        for (uint256 i = 0; i < borrowedTokens.length; i++) total = total.add(initialBorrowPrice(borrowedTokens[i], account_));
        return total;
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowPrice(
        IERC20 borrowed_,
        uint256 price_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowPrice[borrowed_] = price_;
    }

    // Get the initial borrow block for an ccount
    function initialBorrowBlock(IERC20 borrowed_, address account_) public view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialBorrowBlock[borrowed_];
    }

    // Set the initial borrow price for an account
    function _setInitialBorrowBlock(
        IERC20 borrowed_,
        uint256 block_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.initialBorrowBlock[borrowed_] = block_;
    }

    // Check if an account is currently borrowing
    function isBorrowing(address account_) public view returns (bool) {
        Account storage account = _accounts[account_];

        console.log("Has borrowed");
        console.log(account_);
        console.log(account.hasBorrowed);
        console.log("");

        return account.hasBorrowed > 0;
    }

    // Check if an account is currently borrowing a particular asset
    function isBorrowing(IERC20 borrowed_, address account_) public view returns (bool) {
        return borrowed(borrowed_, account_) > 0;
    }

    // Get the interest accumulated for a given asset
    function interest(IERC20 borrowed_, address account_) public view returns (uint256) {
        uint256 borrowPrice = _borrowedPrice(borrowed_, account_);
        uint256 initBorrowPrice = initialBorrowPrice(borrowed_, account_);

        uint256 interestPrice;
        if (borrowPrice > initBorrowPrice) interestPrice = borrowPrice;
        else interestPrice = initBorrowPrice;

        return pool.interest(borrowed_, interestPrice, initialBorrowBlock(borrowed_, account_));
    }

    // Get the interest accumulated for the total account
    function interest(address account_) public view returns (uint256) {
        IERC20[] memory borrowedTokens = _borrowedTokens(account_);
        uint256 total = 0;
        for (uint256 i = 0; i < borrowedTokens.length; i++) total = total.add(interest(borrowedTokens[i], account_));
        return total;
    }
}
