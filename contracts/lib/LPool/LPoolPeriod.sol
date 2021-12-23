//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LPoolCore.sol";

abstract contract LPoolPeriod is LPoolCore {
    using SafeMath for uint256;

    uint256 public immutable periodLength;
    uint256 public immutable cooldownLength;

    constructor(uint256 periodLength_, uint256 cooldownLength_) {
        periodLength = periodLength_;
        cooldownLength = cooldownLength_;
    }

    /** @dev Get the times at which the prologue of the given period occurs */
    function prologueTimes(uint256 _periodId) public view returns (uint256, uint256) {
        uint256 prologueStart = _periodId.mul(periodLength);
        uint256 prologueEnd = prologueStart.add(cooldownLength);
        return (prologueStart, prologueEnd);
    }

    /** @dev Checks if the given period is in the prologue phase */
    function isPrologue(uint256 _periodId) public view returns (bool) {
        (uint256 prologueStart, uint256 prologueEnd) = prologueTimes(_periodId);

        uint256 current = block.timestamp;
        return (current >= prologueStart && current < prologueEnd);
    }

    /** @dev Get the times at which the epilogue of the given period occurs */
    function epilogueTimes(uint256 _periodId) public view returns (uint256, uint256) {
        uint256 periodId = _periodId.add(1);
        uint256 epilogueEnd = periodId.mul(periodLength);
        uint256 epilogueStart = epilogueEnd.sub(cooldownLength);
        return (epilogueStart, epilogueEnd);
    }

    /** @dev Checks if the given period is in the epilogue phase */
    function isEpilogue(uint256 _periodId) public view returns (bool) {
        (uint256 epilogueStart, uint256 epilogueEnd) = epilogueTimes(_periodId);

        uint256 current = block.timestamp;
        return (current >= epilogueStart && current < epilogueEnd);
    }

    /** @dev Checks if the specified period is the current period */
    function isCurrentPeriod(uint256 _periodId) public view returns (bool) {
        return _periodId == currentPeriodId();
    }

    /** @dev Returns the id of the current period */
    function currentPeriodId() public view returns (uint256) {
        return uint256(block.timestamp).div(periodLength);
    }
}