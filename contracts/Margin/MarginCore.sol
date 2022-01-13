//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Oracle/IOracle.sol";
import "../LPool/LPool.sol";

abstract contract MarginCore is Ownable {
    LPool public pool;
    IOracle public oracle;

    constructor(LPool pool_, IOracle oracle_) {
        pool = pool_;
        oracle = oracle_;
    }

    // Set the pool to use
    function setPool(LPool pool_) external onlyOwner {
        pool = pool_;
    }

    // Set the oracle to use
    function setOracle(IOracle oracle_) external onlyOwner {
        oracle = oracle_;
    }
}
