//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ILiquidator {
    /**
     *  @dev Liquidates the assets and returns the amount back to the specified pool and returns true if the callback was successful
     *  @param _initiator The caller of the function that executed this callback
     *  @param _collateral The address of the token received
     *  @param _amount The amount of collateral
     *  @param _borrow The token that was borrowed and needs to be returned to
     *  @param _owing The amount required to be returned to the pool
     *  @param _data Data to be passed to the callback
     */
    function onFlashLiquidate(address _initiator, address _collateral, uint256 _amount, address _borrow, uint256 _owing, bytes memory _data) external returns (bool);
}