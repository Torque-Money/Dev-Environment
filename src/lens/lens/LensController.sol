//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

import {ILensController} from "../../interfaces/lens/ILensController.sol";

import {ILens} from "../../interfaces/lens/ILens.sol";

contract LensController is ILensController {
    // Get the lens that the controller controls.
    function getLens() external view override returns (ILens lens) {}

    // Returns whether or not the lens can update the strategy.
    function isUpdateable() external view override returns (bool _isUpdateable) {}

    // Update the strategy.
    function update() external override {}
}