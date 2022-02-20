//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Set} from "../../../lib/Set.sol";
import {TreasurerCore} from "./TreasurerCore.sol";

abstract contract TreasurerApproved is TreasurerCore {
    using Set for Set.AddressSet;

    mapping(address => bool) private _stakeTokens;
    mapping(address => bool) private _approvedStakeTokens;
    Set.AddressSet private _approvedStakeTokensSet;

    modifier onlyStakeToken(address token_) {
        require(isStakeToken(token_), "TreasurerApproved: Only stake tokens may be used");
        _;
    }

    modifier onlyApprovedStakeToken(address token_) {
        require(isApprovedStakeToken(token_), "TreasurerApproved: Only approved stake tokens may be used");
        _;
    }

    // Add stake tokens
    function addStakeToken(address[] memory token_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (!isStakeToken(token_[i])) {
                _stakeTokens[token_[i]] = true;

                emit AddStakeToken(token_[i]);
            }
        }
    }

    // Approve stake tokens
    function approveStakeToken(address[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (isStakeToken(token_[i])) {
                _approvedStakeTokens[token_[i]] = approved_[i];

                if (_approvedStakeTokens[token_[i]] && !_approvedStakeTokensSet.exists(token_[i])) _approvedStakeTokensSet.insert(token_[i]);
                else if (!_approvedStakeTokens[token_[i]] && _approvedStakeTokensSet.exists(token_[i])) _approvedStakeTokensSet.remove(token_[i]);
            }
        }
    }

    // Get the approved stake tokens list
    function _approvedStakeTokensList() internal view returns (address[] memory) {
        return _approvedStakeTokensSet.iterable();
    }

    // Check if a token is a stake token
    function isStakeToken(address token_) public view returns (bool) {
        return _stakeTokens[token_] || token_ == reserveToken;
    }

    // Check if a token is a stake approved token
    function isApprovedStakeToken(address token_) public view returns (bool) {
        return (isStakeToken(token_) && _approvedStakeTokens[token_]) || token_ == reserveToken;
    }

    event AddStakeToken(address token);
}
