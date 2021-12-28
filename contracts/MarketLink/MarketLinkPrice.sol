//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MarketLinkRouter.sol";

abstract contract MarketLinkPrice is MarketLinkRouter {
    using SafeMath for uint256;

    // Get the price between an LP token or regular token and another LP token or regular token
    function swapPrice(IERC20 _token1, uint256 _amount, IERC20 _token2) external view returns (uint256) {
        address[] memory path = new address[](2);

        if (pool.isLPToken(_token1)) {
            _amount = pool.redeemValue(_token1, _amount);
            path[0] = address(pool.tokenFromLPToken(_token1));
        } else {
            path[0] = address(_token1);
        }

        bool token2IsLP = pool.isLPToken(_token2);
        if (token2IsLP) {
            path[1] = address(pool.tokenFromLPToken(_token2));
        } else {
            path[1] = address(_token2);
        }

        uint256 swappedAmount = router.getAmountsOut(_amount, path)[1];

        if (token2IsLP) {
            // **** I need to be able to determine the stake value algorithmically somehow - I must do this the manual way by adding another hook
        } else {
            return swappedAmount;
        }
    }
}