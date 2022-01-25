//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginLongCore.sol";

abstract contract MarginLongBorrow is MarginLongCore {
    using SafeMath for uint256;

    // Margin borrow against collateral
    function borrow(IERC20 token_, uint256 amount_) external onlyApprovedBorrowedToken(token_) {
        require(amount_ > 0, "MarginLongBorrow: Amount borrowed must be greater than 0");

        if (!isBorrowing(token_, _msgSender())) {
            _setInitialBorrowBlock(token_, block.number, _msgSender());
            _addAccount(_msgSender());
        }

        pool.claim(token_, amount_);
        _setBorrowed(token_, borrowed(token_, _msgSender()).add(amount_), _msgSender());

        uint256 _initialBorrowPrice = oracle.priceMin(token_, amount_);
        _setInitialBorrowPrice(token_, initialBorrowPrice(token_, _msgSender()).add(_initialBorrowPrice), _msgSender());

        require(!resettable(_msgSender()) && !liquidatable(_msgSender()), "MarginLongBorrow: Borrowing desired amount puts account at risk");

        emit Borrow(_msgSender(), token_, amount_);
    }

    event Borrow(address indexed account, IERC20 token, uint256 amount);
}
