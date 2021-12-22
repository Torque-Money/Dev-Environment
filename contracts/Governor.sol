//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

// **** Maybe move this seperate extension into its own seperate file
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO is Governor, GovernorSettings, GovernorCompatibilityBravo, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    using SafeMath for uint256;

    address public taxAccount;
    uint256 public immutable taxPercent;
    IERC20 public payoutToken;

    uint256 public payoutId;
    struct Payout {
        mapping(uint256 => address) voters;
        uint256 index;
        mapping(address => bool) hasVoted;
    }
    mapping(uint256 => Payout) private VoterPayouts;
    uint256 public maxPaidVoters;

    uint256 public lastPayout;
    uint256 public immutable payoutCooldown;

    constructor(
        ERC20Votes token_, TimelockController timelock_, uint256 _quorumFraction, uint256 _votingDelay,
        uint256 _votingPeriod, uint256 _proposalThreshold, uint256 taxPercent_, uint256 maxPaidVoters_, uint256 payoutCooldown_
    )
        Governor("WabbitDAO")
        GovernorSettings(_votingDelay, _votingPeriod, _proposalThreshold)
        GovernorVotes(token_)
        GovernorVotesQuorumFraction(_quorumFraction)
        GovernorTimelockControl(timelock_)
    {
        taxAccount = _msgSender();
        taxPercent = taxPercent_;

        maxPaidVoters = maxPaidVoters_;
        payoutCooldown = payoutCooldown_;
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
    ) internal override returns (uint256) {
        uint256 weight = super._castVote(proposalId, account, support, reason);

        Payout storage _payout = VoterPayouts[payoutId];
        if (!_payout.hasVoted[account]) {
            uint256 index = _payout.index;
            if (index < 2) index = 2; // Number 0 and 1 slots should be dedicated to owner and executor

            _payout.voters[index] = account;
            _payout.hasVoted[account] = true;

            _payout.index = index.add(1).mod(maxPaidVoters.add(2)); // Add 2 to compensate for the slots taken by the owner and executor
        }

        return weight;
    }

    /** @dev Payout the voters with funds */
    function payout() external {
        require(block.timestamp >= lastPayout.add(payoutCooldown), "Not enough time since last payout");

        // Execute the transaction which pays the tokens out, but how will we actually do this without some sort of delegate call ???
    }

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotes)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(Governor, IGovernor, GovernorCompatibilityBravo)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
