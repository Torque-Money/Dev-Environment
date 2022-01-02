//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Governance/Token.sol";

contract YieldCore is Ownable {
    Token public token;

    constructor(Token token_) {
        token = token_;
    }

    // Set the yield distribution token
    function setToken(Token token_) external onlyOwner {
        token = token_;
    }
}