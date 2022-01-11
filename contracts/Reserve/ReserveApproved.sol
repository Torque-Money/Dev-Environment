//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/Set.sol";
import "./ReserveCore.sol";

abstract contract ReserveApproved is ReserveCore {
    using Set for Set.TokenSet;

    Set.TokenSet private _approvedTokens;

    modifier onlyApproved(IERC20 token_) {
        require(isApproved(token_), "Only approved tokens may be used");
        _;
    }

    // Approve tokens to be used with the reserve
    function setApproved(IERC20[] memory token_, bool[] memory approved_) external onlyOwner {
        for (uint256 i = 0; i < token_.length; i++) {
            if (approved_[i] && !isApproved(token_[i])) {
                _approvedTokens.insert(token_[i]);
            } else if (!approved_[i] && isApproved(token_[i])) {
                _approvedTokens.remove(token_[i]);
            }
        }
    }

    // Check if a token is approved
    function isApproved(IERC20 token_) public view returns (bool) {
        return _approvedTokens.exists(token_);
    }

    // Return a list of approved tokens
    function _approved() internal view returns (IERC20[] memory) {
        return _approvedTokens.iterable();
    }
}
