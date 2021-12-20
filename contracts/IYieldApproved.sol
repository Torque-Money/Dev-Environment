//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IYieldApproved {
    /**
     *  @dev Check if an account is approved to yield tokens
     *  @param _account The account to check the yield of
     */
    function yieldApproved(address _account) external returns (bool);
}