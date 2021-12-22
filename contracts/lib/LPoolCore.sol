//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// **** Dont forget to add some sort of approval in here for liquidity accessors using grant role or something instead of ownable ???

contract LPoolCore is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant POOL_ADMIN = keccak256("POOL_ADMIN");
    bytes32 public constant POOL_APPROVED = keccak256("POOL_APPROVED");

    IERC20[] private ApprovedList;
    mapping(IERC20 => bool) private Approved; // Token => approved

    struct StakingPeriod {
        uint256 totalDeposited;
        uint256 liquidity;
        mapping(address => uint256) deposits;

        uint256 totalClaimed;
        mapping(address => uint256) claims;
    }

    uint256 public immutable periodLength;
    uint256 public immutable cooldownLength;

    constructor(uint256 periodLength_, uint256 cooldownLength_) {
        _setRoleAdmin(POOL_APPROVED, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());

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
    function approveToken(IERC20 _token) external onlyRole(POOL_ADMIN) {
        require(!isApproved(_token), "This token has already been approved");

        Approved[_token] = true;
        ApprovedList.push(_token);
    }

    /** @dev Return the approved list of tokens */
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