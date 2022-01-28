//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract MarginCore is Initializable, OwnableUpgradeable {
    address public pool;
    address public oracle;

    function initializeMarginCore(address pool_, address oracle_) public initializer {
        __Ownable_init();

        pool = pool_;
        oracle = oracle_;
    }

    // Set the pool to use
    function setPool(address pool_) external onlyOwner {
        pool = pool_;
    }

    // Set the oracle to use
    function setOracle(address oracle_) external onlyOwner {
        oracle = oracle_;
    }
}
