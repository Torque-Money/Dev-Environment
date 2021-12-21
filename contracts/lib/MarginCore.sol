//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Oracle.sol";
import "../LPool.sol";

contract MarginCore is Ownable {
    Oracle public immutable oracle;
    LPool public immutable pool;

    uint256 public minBorrowLength;
    uint256 public minMarginThreshold; // Stored as the percentage above equilibrium threshold

    uint256 public maxInterestPercent;

    constructor() {}
}