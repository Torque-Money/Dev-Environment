// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITaskTreasury {
    function depositFunds(
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable;

    function userTokenBalance(address _receiver, address _token) external view returns (uint256);
}
