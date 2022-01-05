//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../LPool/LPool.sol";
import "../Governance/Token.sol";
import "./YieldStake.sol";

contract Yield is YieldStake {
    constructor(Token token_, LPool pool_) YieldCore(token_) {}
}
