//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LPoolCore is Ownable {
    using SafeMath for uint256;

    IERC20[] private ApprovedList;
    mapping(IERC20 => bool) private Approved; // Token => approved

    uint256 public immutable periodLength;
    uint256 public immutable cooldownLength;

    constructor(uint256 periodLength_, uint256 cooldownLength_) {
        periodLength = periodLength_;
        cooldownLength = cooldownLength_;
    }

    // ======== Check the staking period and cooldown periods ========

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

    // ======== Approved tokens ========

    /** @dev Approves a token for use with the protocol */
    function approveToken(IERC20 _token) external onlyOwner {
        require(!isApproved(_token), "This token has already been approved");

        Approved[_token] = true;
        ApprovedList.push(_token);
    }

    function approvedList() external view returns (IERC20[] memory) {
        return ApprovedList;
    }

    /** @dev Returns whether or not a token is approved */
    function isApproved(IERC20 _token) public view returns (bool) {
        return Approved[_token];
    }

    modifier onlyApproved(IERC20 _token) {
        require(isApproved(_token), "This token has not been approved");
        _;
    }
}