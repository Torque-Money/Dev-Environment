//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../Governance/Token.sol";
import "../Oracle/IOracle.sol";
import "./ReserveStake.sol";
import "./ReserveRedeem.sol";

contract Reserve is ReserveStake, ReserveRedeem {
    constructor(Token token_, IOracle oracle_) ReserveCore(token_, oracle_) {}
}
