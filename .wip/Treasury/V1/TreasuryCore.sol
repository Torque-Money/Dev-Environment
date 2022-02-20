//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract TreasuryCore is Initializable, OwnableUpgradeable {
    address public oracle;

    address public reserveToken;

    function initializeTreasuryCore(address oracle_, address reserveToken_) public initializer {
        oracle = oracle_;
        reserveToken = reserveToken_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyOwner {
        oracle = oracle_;
    }

    // Set the reserve token to use
    function setReserveToken(address reserveToken_) external onlyOwner {
        reserveToken = reserveToken_;
    }
}
