//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./MarginPool.sol";

abstract contract MarginCollateral is MarginPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Account {
        IERC20[] collateral;
        mapping(uint256 => uint256) indexes;

        
    }

    mapping(IERC20 => mapping(address => uint256)) private _borrowed;
    mapping(IERC20 => mapping(address => uint256)) private _collateral;

    // **** I want a way of being able to hold all of the assets and check the value of them, then add and remove when we add and subtract different assets
}