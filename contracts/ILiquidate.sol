//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ILiquidator {
    /**
     *  @dev Liquidates the assets and returns the amount back to the specified pool
     *  @param _initiator The caller of the function that executed this callback
     *  @param _token The address of the token received
     *  @param _amount The amount of the token received
     *  @param _owing The amount required to be returned to the pool
     *  @param _data Data to be passed to the callback
     */
    function onFlashLiquidate(address _initiator, address _token, uint256 _amount, uint256 _owing, bytes memory _data) external returns (bool);
}