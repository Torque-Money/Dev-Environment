//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../Governance/Token.sol";
import "../Oracle/Oracle.sol";
import "./ReserveStake.sol";

contract Reserve is ReserveStake {
    constructor(Token token_, Oracle oracle_) ReserveCore(token_) {}
}
