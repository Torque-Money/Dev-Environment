//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {ISupportsToken} from "../interfaces/utils/ISupportsToken.sol";

contract SupportsTokenUpgradeable is Initializable, ISupportsToken {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private tokenSet;

    function __SupportsToken_init(IERC20Upgradeable[] memory token) internal onlyInitializing {
        __SupportsToken_init_unchained(token);
    }

    function __SupportsToken_init_unchained(IERC20Upgradeable[] memory token) internal onlyInitializing {
        require(token.length > 0, "SupportsToken: Contract must support at least one token");
        for (uint256 i = 0; i < token.length; i++) tokenSet.add(address(token[i]));
    }

    modifier onlySupportedToken(IERC20Upgradeable token) {
        require(isSupportedToken(token), "SupportsToken: Only supported tokens are allowed");
        _;
    }

    modifier onlyTokenAmount(uint256[] memory amount) {
        require(amount.length == tokenCount(), "SupportsToken: Token amount length must match support token count");
        _;
    }

    function isSupportedToken(IERC20Upgradeable token) public view virtual override returns (bool supportedToken) {
        return tokenSet.contains(address(token));
    }

    function tokenCount() public view virtual override returns (uint256 count) {
        return tokenSet.length();
    }

    function tokenByIndex(uint256 index) public view virtual override returns (IERC20Upgradeable token) {
        require(index < tokenCount(), "SupportsToken: Index must be less than count");
        return IERC20Upgradeable(tokenSet.at(index));
    }

    function approxBalance(IERC20Upgradeable token) public view virtual override onlySupportedToken(token) returns (uint256 amount) {
        return token.balanceOf(address(this));
    }

    function approxAvailable(IERC20Upgradeable token) public view override onlySupportedToken(token) returns (uint256 amount) {
        return approxBalance(token);
    }
}
