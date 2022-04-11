//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {OracleCore} from "./OracleCore.sol";

abstract contract OracleApproved is OracleCore {
    struct Approved {
        address priceFeed;
        uint256 decimals;
        bool approved;
    }

    mapping(address => Approved) private _approved;

    // Set the approved price feed for a given asset along with the decimals
    function setApprovedPriceFeed(
        address[] memory token_,
        address[] memory priceFeed_,
        uint256[] memory correctDecimals_,
        bool[] memory approved_
    ) external onlyRole(ORACLE_ADMIN) {
        for (uint256 i = 0; i < token_.length; i++) {
            Approved storage approved = _approved[token_[i]];

            approved.priceFeed = priceFeed_[i];
            approved.decimals = correctDecimals_[i];
            approved.approved = approved_[i];
        }
    }

    // Get the price feed for a given asset
    function priceFeed(address token_) public view onlyApproved(token_) returns (address) {
        Approved memory approved = _approved[token_];
        return approved.priceFeed;
    }

    // Get the correct decimals for a given asset
    function decimals(address token_) public view onlyApproved(token_) returns (uint256) {
        Approved memory approved = _approved[token_];
        return approved.decimals;
    }

    // Check if an asset is supported by the oracle
    function isApproved(address token_) public view returns (bool) {
        Approved memory approved = _approved[token_];
        return approved.approved;
    }

    modifier onlyApproved(address token_) {
        require(isApproved(token_), "OracleApproved: Only approved tokens may be used");
        _;
    }
}
