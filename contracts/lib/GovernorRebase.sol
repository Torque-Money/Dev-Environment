//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract GovernorRebase is Governor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public taxAccount;
    uint256 public immutable taxPercent;

    IERC20 public rebaseToken;
    uint256 public immutable rebasePercent;

    uint256 public lastRebase;
    uint256 public immutable rebaseCooldown;

    uint256 public minVotingPower;

    uint256 public rebaseId;
    struct RebaseReceiver {
        uint256[] receivers;
        mapping(address => bool) hasReceived; // **** If I modified delegate a bit I could prevent people from transferring tokens over and replacing money this way
    }
    mapping(uint256 => RebaseReceiver) private RebaseReceivers;

    constructor(uint256 taxPercent_, uint256 rebaseCooldown_, uint256 rebasePercent_, uint256 minVotingPower_) {
        taxAccount = _msgSender();
        taxPercent = taxPercent_;

        rebaseCooldown = rebaseCooldown_;
        rebasePercent = rebasePercent_;
        minVotingPower = minVotingPower_;
    }

    function setTaxAccount(address _account) external {
        require(_msgSender() == taxAccount, "Only the current tax account may set the new tax account");
        taxAccount = _account;
    }

    function setRebaseToken(IERC20 _token) external onlyGovernance {
        rebaseToken = _token;
    }

    function setMinVotingPower(uint256 _votingPower) external onlyGovernance {
        minVotingPower = _votingPower;
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual override returns (uint256) {
        return super._castVote(proposalId, account, support, reason);
    }

    function rebase() external onlyGovernance {

    }

    // **** How is the structure actually going to work ?
    // 1. Every vote should for a given payout period should track the votes of the owner - if they are above a certain threshold then add them to the payout list
    // 2. A proposal should be made to payout those same stakeholders from the protocol itself with an agreed upon amount by the protocol

    function timelock() public view virtual returns (address);

    event Rebase();
}