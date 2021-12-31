//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./YieldCore.sol";

abstract contract YieldAccount is YieldCore {
    using SafeMath for uint256;

    struct Account {
        uint256 amount;
        uint256 initialStakeBlock;
    }

    mapping(IERC20 => mapping(address => Account)) private _accounts;
    mapping(address => uint256) private _owedBalances;
    mapping(IERC20 => uint256) private _totalStaked;

    // Return the amount of the token staked for a given account
    function staked(IERC20 token_, address account_) public view returns (uint256) {
        return _accounts[token_][account_].amount;
    }

    // Set the amount staked for a given account
    function _setStaked(IERC20 token_, uint256 amount_, address account_) internal {
        Account storage account = _accounts[token_][account_];
        _totalStaked[token_] = _totalStaked[token_].sub(account.amount).add(amount_);
        account.amount = amount_;
    }

    // Get the owed balance of the account
    function _owedBalance(address account_) internal view returns (uint256) {
        return _owedBalances[account_];
    }

    // Set the owed balance of an account
    function _setOwedBalance(uint256 amount_, address account_) internal {
        _owedBalances[account_] = amount_;
    }

    // Get the block of when the initial stake was made
    function initialStakeBlock(IERC20 token_, address account_) public view returns (uint256) {
        Account storage account = _accounts[token_][account_];
        return account.initialStakeBlock;
    }

    // Set the initial stake block
    function _setInitialStakeBlock(IERC20 token_, uint256 block_, address account_) internal {
        Account storage account = _accounts[token_][account_];
        account.initialStakeBlock = block_;
    }

    // Get the total amount of a given token staked
    function totalStaked(IERC20 token_) external view returns (uint256) {
        return _totalStaked[token_];
    }
}