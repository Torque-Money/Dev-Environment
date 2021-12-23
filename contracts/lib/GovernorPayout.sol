//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract GovernorPayout is Governor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public taxAccount;
    uint256 public immutable taxPercent;

    uint256 public payoutId;
    struct Payout {
        mapping(uint256 => address) voters;
        uint256 index;
        mapping(address => bool) hasVoted;

        bool requested;
        address requester;
        bool completed;

        IERC20 token;
        uint256 amount;
    }
    mapping(uint256 => Payout) private VoterPayouts;
    uint256 public maxPaidVoters;
    IERC20 public payoutToken;
    uint256 public immutable payoutPercent;

    uint256 public lastPayout;
    uint256 public immutable payoutCooldown;

    constructor(uint256 taxPercent_, uint256 maxPaidVoters_, uint256 payoutCooldown_, uint256 payoutPercent_) {
        taxAccount = _msgSender();
        taxPercent = taxPercent_;

        maxPaidVoters = maxPaidVoters_;
        payoutCooldown = payoutCooldown_;
        payoutPercent = payoutPercent_;
    }

    /** @dev Let the current tax account set a new tax account */
    function setTaxAccount(address _account) external {
        require(_msgSender() == taxAccount, "Only the current tax account may set the new tax account");
        taxAccount = _account;
    }

    /** @dev Set the payout token */
    function setPayoutToken(IERC20 _token) external onlyGovernance {
        payoutToken = _token;
    }

    /** @dev Add a voter to the voter reward payout list */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual override returns (uint256) {
        uint256 weight = super._castVote(proposalId, account, support, reason);

        Payout storage _payout = VoterPayouts[payoutId];
        if (!_payout.hasVoted[account]) {
            uint256 index = _payout.index;
            if (index < 1) index = 1; // Number 0 and 1 slots should be dedicated to owner and executor

            _payout.voters[index] = account;
            _payout.hasVoted[account] = true;

            _payout.index = index.add(1).mod(maxPaidVoters.add(1)); // Add 2 to compensate for the slots taken by the owner and executor
        }

        return weight;
    }

    /** @dev Request a payout to the voters for the timelock to fulfill */
    function requestPayout() external {
        require(block.timestamp >= lastPayout.add(payoutCooldown), "Not enough time since last payout");

        Payout storage _payout = VoterPayouts[payoutId];
        _payout.requested = true;
        _payout.requester = _msgSender();
        _payout.token = payoutToken;

        // Get the amount of the token to be distributed back to the users
        uint256 balance = IERC20(payoutToken).balanceOf(timelock());
        uint256 payoutAmount = balance.mul(payoutPercent).div(100);
        _payout.amount = payoutAmount;

        lastPayout = block.timestamp;
        payoutId = payoutId.add(1);

        // **** Now we need to queue the payout function as well as the approve the tokens
    }

    /** @dev Used by the timelock to distribute the tokens
     *  NOTE: if the payout is executed and the liquidity of the protocol is different, this will have to be rexecuted
     */
    function payout(uint256 _payoutId) external onlyGovernance {
        Payout storage _payout = VoterPayouts[_payoutId];
        require(_payout.requested && !_payout.completed, "Not eligible for payout to occur");

        // Special payout for the tax account and the caller
        IERC20 token = _payout.token;
        uint256 tax = _payout.amount.mul(taxPercent).div(100);
        token.safeTransferFrom(timelock(), taxAccount, tax);

        // **** It would be in my best interest to introduce a length incase there are not enough voters to fulfill the quarter
        mapping(uint256 => address) storage voters = _payout.voters;
        for (uint256 i = 1; i < maxPaidVoters.add(1); i++) {
                
        }

        _payout.completed = true;
    }

    /** @dev Override from the GovernorTimelockControl */
    function timelock() public view virtual returns (address);
}