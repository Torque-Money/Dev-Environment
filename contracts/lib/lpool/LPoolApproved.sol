//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPoolCore.sol";

contract LPoolApproved is LPoolCore {
    IERC20[] private ApprovedList;
    mapping(IERC20 => bool) private Approved; // Token => approved

    /** @dev Approves a token for use with the protocol */
    function approveToken(IERC20 _token) external onlyRole(POOL_ADMIN) {
        require(!isApproved(_token), "This token has already been approved");

        Approved[_token] = true;
        ApprovedList.push(_token);
    }

    /** @dev Return the approved list of tokens */
    function approvedList() external view returns (IERC20[] memory) {
        return ApprovedList;
    }

    /** @dev Returns whether or not a token is approved */
    function isApproved(IERC20 _token) public view returns (bool) {
        return Approved[_token];
    }

    modifier onlyApproved(IERC20 _token) {
        require(isApproved(_token), "This token has not been approved");
        _;
    }
}