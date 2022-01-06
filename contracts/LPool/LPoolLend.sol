//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolApproved.sol";

abstract contract LPoolLend is LPoolApproved {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => mapping(IERC20 => uint256)) private _loaned;
    mapping(IERC20 => uint256) private _totalLoaned;

    // Lend out collateral to an approved account
    function loan(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyPA(token_) {
        require(amount_ <= liquidity(token_), "Withdraw amount exceeds available liquidity");
        token_.safeTransfer(_msgSender(), amount_);
        _loaned[_msgSender()][token_] = _loaned[_msgSender()][token_].add(amount_);
        emit Loaned(_msgSender(), token_, amount_);
    }

    // Repay collateral from an account
    function repay(IERC20 token_, uint256 amount_) external onlyRole(POOL_APPROVED) onlyPA(token_) {
        token_.safeTransferFrom(_msgSender(), address(this), amount_);
        if (amount_ > _loaned[_msgSender()][token_]) _loaned[_msgSender()][token_] = 0;
        else _loaned[_msgSender()][token_] = _loaned[_msgSender()][token_].sub(amount_);
        emit Repay(_msgSender(), token_, amount_);
    }

    // Get the total amount an account has been loaned
    function loaned(IERC20 token_, address account_) external view returns (uint256) {
        return _loaned[account_][token_];
    }

    // Get the total amount loaned
    function totalLoaned(IERC20 token_) public view returns (uint256) {
        return _totalLoaned[token_];
    }

    function liquidity(IERC20 token_) public view virtual returns (uint256);

    event Loaned(address indexed account, IERC20 token, uint256 amount);
    event Repay(address indexed account, IERC20 token, uint256 amount);
}
