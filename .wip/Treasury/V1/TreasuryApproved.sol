//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Set} from "../../lib/Set.sol";
import {TreasuryCore} from "./TreasuryCore.sol";

abstract contract TreasuryApproved is TreasuryCore {
    using Set for Set.AddressSet;

    mapping(address => bool) private _approvedTreasuryAssets;
    Set.AddressSet private _approvedTreasuryAssetsSet;

    modifier onlyApprovedTreasuryAsset(address token_) {
        require(isApprovedTreasuryAsset(token_), "TreasuryApproved: Only approved treasury assets may be used");
        _;
    }

    // Approve treasury tokens
    function setApprovedTreasuryToken(address[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (token_[i] != reserveToken) {
                _approvedTreasuryAssets[token_[i]] = approved_[i];

                if (_approvedTreasuryAssets[token_[i]] && !_approvedTreasuryAssetsSet.exists(token_[i])) _approvedTreasuryAssetsSet.insert(token_[i]);
                else if (!_approvedTreasuryAssets[token_[i]] && _approvedTreasuryAssetsSet.exists(token_[i])) _approvedTreasuryAssetsSet.remove(token_[i]);
            }
        }
    }

    // Get the approved treasury token list
    function _approvedTreasuryAssetsList() internal view returns (address[] memory) {
        return _approvedTreasuryAssetsSet.iterable();
    }

    // Check if a token is an approved treasury asset
    function isApprovedTreasuryAsset(address token_) public view returns (bool) {
        return _approvedTreasuryAssets[token_];
    }
}
