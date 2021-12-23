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

    IERC20 public payoutToken;
    uint256 public immutable payoutPercent;

    uint256 public lastPayout;
    uint256 public immutable payoutCooldown;

    constructor(uint256 taxPercent_, uint256 payoutCooldown_, uint256 payoutPercent_) {
        taxAccount = _msgSender();
        taxPercent = taxPercent_;

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

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual override returns (uint256) {
        return super._castVote(proposalId, account, support, reason);
    }

    function timelock() public view virtual returns (address);
}