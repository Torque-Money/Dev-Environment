//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./VPool.sol";

contract YieldApproved {
    using SafeMath for uint256;

    // **** Essentially here we are going to keep track of all of the previous yielders and make sure that no double yields occur, then the DAO will use this to determine where or not a yield should be made

    function yieldApproved(address _account) {

    }
}