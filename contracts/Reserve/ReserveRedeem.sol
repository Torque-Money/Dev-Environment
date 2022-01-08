//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ReserveApproved.sol";
import "./ReserveStakeAccount.sol";

abstract contract ReserveRedeem is ReserveApproved, ReserveStakeAccount {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Get the total liquidity price of the reserve
    function totalPrice() public view returns (uint256) {
        uint256 _totalPrice = 0;

        IERC20[] memory approved = _approved();
        for (uint256 i = 0; i < approved.length; i++) {
            uint256 staked = totalStaked(approved[i]);
            uint256 available = approved[i].balanceOf(address(this)).sub(staked);

            uint256 price = oracle.price(approved[i], available);
            _totalPrice = _totalPrice.add(price);
        }

        return _totalPrice;
    }

    // Get the amount of tokens received for redeeming tokens
    function redeemValue(uint256 amount_, IERC20 token_) public view returns (uint256) {
        uint256 _totalPrice = totalPrice();
        uint256 totalSupply = token.totalSupply();

        uint256 entitledPrice = amount_.mul(_totalPrice).div(totalSupply);
        uint256 entitledAmount = oracle.amount(token_, entitledPrice);

        return entitledAmount;
    }

    // Redeem tokens for the underlying reserve asset
    function redeem(uint256 amount_, IERC20 token_) external onlyApproved(token_) returns (uint256) {
        token.burn(_msgSender(), amount_);

        uint256 _redeemValue = redeemValue(amount_, token_);
        token_.safeTransfer(_msgSender(), _redeemValue);

        emit Redeem(_msgSender(), amount_, token_, _redeemValue);

        return _redeemValue;
    }

    event Redeem(address indexed account, uint256 amount, IERC20 redeemToken, uint256 redeemValue);
}
