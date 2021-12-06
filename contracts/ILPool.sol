//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ILPool {
    /**
     *  @notice approves an asset to be used throughout the protocol and generate a new pool token for it
     *  @param _token address
     *  @param _ltName string
     *  @param _ltSymbol string
     */
    function approveAsset(address _token, string memory _ltName, string memory _ltSymbol) external;

    /**
     *  @notice returns whether a specified asset is approved
     *  @param _token address
     *  @return _isApproved bool
     */
    function isApprovedAsset(address _token) external view returns (bool _isApproved);

    /**
     *  @notice gets the approved asset from a pool token
     *  @param _token address
     *  @return _approvedAsset address
     */
    function getApprovedAsset(address _token) external view returns (address _approvedAsset);

    /**
     *  @notice return the list of assets the protocol may accept
     *  @return _approvedAssets address[]
     */
    function getApprovedAssets() external view returns (address[] memory _approvedAssets);

    /**
     *  @notice returns whether or not a specified asset is a pool token
     *  @param _token address
     *  @return _isPool bool
     */
    function isPoolToken(address _token) external view returns (bool _isPool);

    /**
     *  @notice returns the pool token that corresponds to an approved asset
     *  @param _token address
     *  @return _poolToken address
     */
    function getPoolToken(address _token) external view returns (address _poolToken);

    /**
     *  @notice calculates the number of tokens received from a deposit
     *  @param _token address
     *  @param _amount uint256
     */
    function depositTokensReceived(address _token, uint256 _amount) external view returns (uint256 _tokensReceived);

    /**
     *  @notice deposits a given amount of assets into the pool and mints a portion of tokens to represent the share
     *  @param _token address
     *  @param _amount uint256
     */
    function deposit(address _token, uint256 _amount) external;

    /**
     *  @notice returns the amount of tokens received from a withdraw
     *  @param _token address
     *  @param _amount uint256
     */
    function withdrawTokensReceived(address _token, uint256 _amount) external view returns (uint256 _tokensReceived);

    /**
     *  @notice withdraws tokens in exchange for the percentage worth in the pool
     *  @param _token address 
     *  @param _amount uint256
     */
    function withdraw(address _token, uint256 _amount) external;

    /**
     *  @notice allows an admin to lend a specific amount of tokens from the pool to a given address
     *  @param _token address
     *  @param _amount uint256
     *  @param _to address
     */
    function lend(address _token, uint256 _amount, address _to) external;

    // ======== Events ========
    event Deposit(address indexed from, address indexed tokenDeposited, uint256 depositAmount, address indexed poolToken, uint256 mintedAmount);
    event Withdraw(address indexed to, address indexed tokenWithdrawn, uint256 withdrawAmount, address indexed poolToken, uint256 burnedAmount);
    event Lend(address indexed token, uint256 amount, address indexed to);
}