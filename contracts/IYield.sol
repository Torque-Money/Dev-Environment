//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYield {
    /**
     *  @dev Return the amount to be yielded to a user
     *  @param _account The account to check if the yield is eligible for
     *  @param _token The token to check if the account is eligible for a yield on
     */
    function yield(address _account, IERC20 _token) external returns (uint256);
}