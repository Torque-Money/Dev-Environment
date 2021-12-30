//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../LPool/LPool.sol";
import "./OraclePriceFeed.sol";

contract Oracle is OraclePriceFeed {
    constructor(LPool pool_)
        OracleCore(pool_)
    {}
}