//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract TreasurerCore is Initializable, OwnableUpgradeable {
    address public oracle;

    address public treasury;

    address public reserveToken;
    address public wrappedReserveToken;

    function initializeReserveCore(
        address oracle_,
        address treasury_,
        address reserveToken_,
        address wrappedReserveToken_
    ) public initializer {
        __Ownable_init();

        oracle = oracle_;

        treasury = treasury_;

        reserveToken = reserveToken_;
        wrappedReserveToken = wrappedReserveToken_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyOwner {
        oracle = oracle_;
    }

    // Set the treasury
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    // Set the reserve token to use
    function setReserveToken(address reserveToken_) external onlyOwner {
        reserveToken = reserveToken_;
    }

    // Set the wrapped reserve token to use
    function setWrappedReserveToken(address wrappedReserveToken_) external onlyOwner {
        wrappedReserveToken = wrappedReserveToken_;
    }
}
