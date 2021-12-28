//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolManipulation.sol";
import "./LPoolToken.sol";

abstract contract LPoolStake is LPoolManipulation {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Stake tokens and receive LP tokens that represent the users share in the pool
    function stake(IERC20 _token, uint256 _amount) external onlyApprovedToken(_token) {
        LPoolToken LPToken = LPoolToken(address(LPTokenFromToken(_token)));

        uint256 totalSupply = LPToken.totalSupply();
        uint256 totalValue = tvl(_token);
        uint256 reward = _amount.mul(totalSupply).div(totalValue);
        require(reward > 0, "Not enough tokens staked");

        _token.safeTransferFrom(_msgSender(), address(this), _amount);
        LPToken.mint(_msgSender(), reward);

        emit Stake(_msgSender(), _token, _amount, reward);
    }

    function _redeemValue(LPoolToken _LPToken, uint256 _amount) internal view onlyLPToken(_lpToken) returns (uint256) {
        IERC20 approvedToken = tokenFromLPToken(IERC20(address(_lpToken)));
        uint256 totalSupply = _LPToken.totalSupply();
        uint256 totalValue = tvl(approvedToken);
        return _amount.mul(totalValue).div(totalSupply);
    }

    // Get the value for redeeming LP tokens for the underlying asset
    function redeemValue(IERC20 _token, uint256 _amount) public view onlyLPToken(_token) returns (uint256) {
        LPoolToken LPToken = LPoolToken(address(_token));
        return _redeemValue(LPToken, _amount);
    }

    // Redeem LP tokens for the underlying asset
    function redeem(IERC20 _token, uint256 _amount) external onlyLPToken(_token) {
        LPoolToken LPToken = LPoolToken(address(_token));
        IERC20 approvedToken = tokenFromLPToken(_token);

        uint256 value = _redeemValue(LPToken, _amount);

        LPToken.burn(_msgSender(), _amount);
        approvedToken.safeTransfer(_msgSender(), value);

        emit Redeem(_msgSender(), _token, _amount, value);
    }

    event Stake(address indexed account, IERC20 token, uint256 amount, uint256 reward);
    event Redeem(address indexed account, IERC20 token, uint256 amount, uint256 reward);
}