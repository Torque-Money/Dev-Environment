//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISupportsToken} from "../interfaces/utils/ISupportsToken.sol";

abstract contract SupportsToken is Initializable, ISupportsToken {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private tokenSet;

    function __SupportsToken_init(IERC20[] memory token) internal onlyInitializing {
        __SupportsToken_init_unchained(token);
    }

    function __SupportsToken_init(IERC20[] memory token, uint256 _tokenCount) internal onlyInitializing {
        __SupportsToken_init_unchained(token, _tokenCount);
    }

    function __SupportsToken_init_unchained(IERC20[] memory token) internal onlyInitializing {
        require(token.length > 0, "SupportsToken: Contract must support at least one token");
        for (uint256 i = 0; i < token.length; i++) tokenSet.add(address(token[i]));
    }

    function __SupportsToken_init_unchained(IERC20[] memory token, uint256 _tokenCount) internal onlyInitializing {
        require(token.length == _tokenCount, "SupportsToken: Number of tokens must match given token count");
        __SupportsToken_init_unchained(token);
    }

    modifier onlySupportedToken(IERC20 token) {
        require(isSupportedToken(token), "SupportsToken: Only supported tokens are allowed");
        _;
    }

    modifier onlyTokenAmount(uint256[] memory amount) {
        require(amount.length == tokenCount(), "SupportsToken: Token amount length must match support token count");
        _;
    }

    function isSupportedToken(IERC20 token) public view returns (bool supportedToken) {
        return tokenSet.contains(address(token));
    }

    function tokenCount() public view returns (uint256 count) {
        return tokenSet.length();
    }

    function tokenByIndex(uint256 index) public view returns (IERC20 token) {
        require(index < tokenCount(), "SupportsToken: Index must be less than count");
        return IERC20(tokenSet.at(index));
    }
}
