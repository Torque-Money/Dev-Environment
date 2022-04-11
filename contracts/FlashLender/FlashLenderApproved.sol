//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {FlashLenderCore} from "./FlashLenderCore.sol";

abstract contract FlashLenderApproved is FlashLenderCore {
    mapping(address => bool) private _approved;

    // Set whether a token is approved
    function setApproved(address[] memory token_, bool[] memory approved_) external onlyRole(FLASHLENDER_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) _approved[token_[i]] = approved_[i];
    }

    // Check if a token is approved
    function isApproved(address token_) public view returns (bool) {
        return _approved[token_];
    }

    modifier onlyApproved(address token_) {
        require(isApproved(token_), "FlashLenderApproved: Only approved tokens may be used");
        _;
    }
}
