//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYield {
    /**
     *  @dev Return the amount to be yielded to a user
     *  @param _account The account to check if the yield is eligible for
     */
    function yield(address _account) external returns (uint256);
}