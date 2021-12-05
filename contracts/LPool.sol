//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPool is Ownable {
    address private wabbit;

    struct ApprovedAsset {
        ERC20 asset;
        address token;
    }
    mapping(address => ApprovedAsset) private approvedAssetsMap;
    ApprovedAsset[] private approvedAssets;

    /**
     *  @param _wabbit address
     */
    constructor(address _wabbit) {
        wabbit = _wabbit;
    }

    /**
     *  @notice approves an asset to be used throughout the protocol
     *  @param _token address
     */
    function approvePoolAsset(address _token) public onlyOwner {
        require(approvedAssetsMap[_token] == false, "This token has already been approved");
        approvedAssets.push(_token);
        approvedAssetsMap[_token] = true;
    }

    /**
     *  @notice returns whether a specified asset is approved
     *  @param _token address
     *  @return _isApproved bool
     */
    function isApprovedAsset(address _token) public view returns (bool _isApproved) {
        _isApproved = approvedAssetsMap[_token];
    }

    /**
     *  @notice return the list of assets the protocol may accept
     *  @return _approvedAssets address[]
     */
    function getApproveAssets() public view returns (address[] memory _approvedAssets) {
        _approvedAssets = approvedAssets;
    }

    /**
     *  @notice deposits a given amount of assets into the pool and mints a portion of tokens to represent the share
     */
    function deposit(address _token, uint256 _amount) public {
        // **** Since the tokens represent a percentage of the total liquidity, they can only redeem the percentage of the pool which they own ?
        require(approvedAssetsMap[_token] == true, "Thi asset is not approved");
    }

    /**
     * @notice withdraws tokens in exchange for the percentage worth in the pool
     */
    function withdraw(address _token, uint256 _amount) public {

    }
}