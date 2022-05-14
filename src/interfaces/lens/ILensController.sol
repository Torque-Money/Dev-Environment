//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ILens} from "./ILens.sol";

interface ILensController {
    // Get the lens that the controller controls.
    function getLens() external view returns (ILens lens);

    // Returns whether or not the lens can update the strategy.
    function isUpdateable() external view returns (bool _isUpdateable);

    // Update the strategy.
    function update() external;
}
