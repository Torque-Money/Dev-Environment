//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {LPool} from "../../LPool/LPool.sol";
import {IOracle} from "../../Oracle/IOracle.sol";

import {MarginLongCore} from "./MarginLongCore.sol";

abstract contract MarginLongBorrow is MarginLongCore {
    using SafeMathUpgradeable for uint256;

    // Margin borrow against collateral
    function borrow(address token_, uint256 amount_) external whenNotPaused onlyApprovedBorrowToken(token_) {
        require(amount_ > 0, "MarginLongBorrow: Amount borrowed must be greater than 0");

        if (!_isBorrowing(_msgSender())) _addAccount(_msgSender());
        _setAccumulatedInterest(token_, interest(token_, _msgSender()), _msgSender());
        _setInitialBorrowTime(token_, block.timestamp, _msgSender());

        LPool(pool).claim(token_, amount_);
        _setBorrowed(token_, borrowed(token_, _msgSender()).add(amount_), _msgSender());

        uint256 _initialBorrowPrice = IOracle(oracle).priceMin(token_, amount_);
        _setInitialBorrowPrice(token_, initialBorrowPrice(token_, _msgSender()).add(_initialBorrowPrice), _msgSender());

        require(!resettable(_msgSender()) && !liquidatable(_msgSender()), "MarginLongBorrow: Borrowing desired amount puts account at risk");

        emit Borrow(_msgSender(), token_, amount_);
    }

    event Borrow(address indexed account, address token, uint256 amount);
}
