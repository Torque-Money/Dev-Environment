//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {WrappedReserveToken} from "../Token/WrappedReserveToken.sol";
import {TreasurerAccount} from "./TreasurerAccount.sol";

abstract contract TreasurerWrappedStake is Initializable, TreasurerAccount {
    using SafeMathUpgradeable for uint256;

    struct WrappedAccount {
        uint256 accumulatedWrappedTokens;
        uint256 outstandingWrappedTokens;
        uint256 recentTimeStaked;
    }

    mapping(address => WrappedAccount) private _wrappedAccounts;

    uint256 public minStakeTime;

    function initializeReserveWrapped(uint256 minStakeTime_) public initializer {
        minStakeTime = minStakeTime_;
    }

    // Set the minimum stake time before wrapped tokens may be withdrawn
    function setMinStakeTime(uint256 minStakeTime_) external onlyOwner {
        minStakeTime = minStakeTime_;
    }

    // Update the accumulated tokens
    function _wrappedStakeUpdate(address account_) internal {
        WrappedAccount storage wrappedAccount = _wrappedAccounts[account_];

        wrappedAccount.accumulatedWrappedTokens = accumulatedWrappedTokens(account_);
        wrappedAccount.recentTimeStaked = block.timestamp;
    }

    // Mint wrapped tokens
    function mintWrappedTokens(uint256 amount_) external {
        _wrappedStakeUpdate(_msgSender());

        require(amount_ > 0, "TreasurerWrapped: Amount of wrapped reserve tokens to mint must be greater than 0");
        require(amount_ <= allowedMintedTokens(_msgSender()), "TreasurerWrapped: Amount of wrapped reserve tokens to mint exceeds allowed amount");

        WrappedAccount storage wrappedAccount = _wrappedAccounts[_msgSender()];
        wrappedAccount.outstandingWrappedTokens = wrappedAccount.outstandingWrappedTokens.add(amount_);
        WrappedReserveToken(reserveToken).mint(_msgSender(), amount_);
    }

    // Burn wrapped tokens
    function burnWrappedTokens(uint256 amount_) external {
        _wrappedStakeUpdate(_msgSender());

        require(amount_ > 0, "TreasurerWrapped: Amount of wrapped reserve tokens to burn must be greater than 0");

        WrappedReserveToken(reserveToken).burn(_msgSender(), amount_);
        WrappedAccount storage wrappedAccount = _wrappedAccounts[_msgSender()];
        wrappedAccount.outstandingWrappedTokens = wrappedAccount.outstandingWrappedTokens.sub(amount_);
    }

    // Calculate the accumulated wrapped tokens for an account
    function accumulatedWrappedTokens(address account_) public view returns (uint256) {
        WrappedAccount memory wrappedAccount = _wrappedAccounts[account_];

        uint256 maxRemainingAmount;
        if (staked(reserveToken, account_) > wrappedAccount.accumulatedWrappedTokens)
            maxRemainingAmount = staked(reserveToken, account_).sub(wrappedAccount.accumulatedWrappedTokens);
        else maxRemainingAmount = 0;
        uint256 remainingIssuableAmount = maxRemainingAmount.mul(block.timestamp.sub(wrappedAccount.recentTimeStaked)).div(minStakeTime);
        uint256 accumulated = remainingIssuableAmount.add(wrappedAccount.accumulatedWrappedTokens);

        return MathUpgradeable.min(accumulated, staked(reserveToken, account_));
    }

    // Get the allowed amount of tokens that can be minted by an account
    function allowedMintedTokens(address account_) public view returns (uint256) {
        WrappedAccount memory wrappedAccount = _wrappedAccounts[account_];
        return accumulatedWrappedTokens(account_).sub(wrappedAccount.outstandingWrappedTokens);
    }

    // Get the amount of outstanding wrapped tokens
    function outstandingWrappedTokens(address account_) public view returns (uint256) {
        WrappedAccount memory wrappedAccount = _wrappedAccounts[account_];
        return wrappedAccount.outstandingWrappedTokens;
    }
}
