//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Governance/Token.sol";
import "../Oracle/Oracle.sol";

contract YieldCore is Ownable {
    Token public token;
    Oracle public oracle;

    constructor(Token token_, Oracle oracle_) {
        token = token_;
        oracle = oracle_;
    }

    // Set the yield distribution token
    function setToken(Token token_) external onlyOwner {
        token = token_;
    }

    // Set the oracle
    function setOracle(Oracle oracle_) external onlyOwner {
        oracle = oracle_;
    }
}
