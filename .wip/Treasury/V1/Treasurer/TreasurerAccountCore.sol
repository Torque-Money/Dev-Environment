//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {Set} from "../../../lib/Set.sol";
import {TreasurerDistributor} from "./TreasurerDistributor.sol";

abstract contract TreasurerAccountCore is TreasurerDistributor {
    using SafeMathUpgradeable for uint256;
    using Set for Set.AddressSet;

    struct Account {
        mapping(address => uint256) stakedAmount;
        mapping(address => uint256) stakedEpoch;
        Set.AddressSet stakedTokens;
        uint256 isStaking;
        uint256 initialStakeEpoch;
    }

    mapping(address => Account) private _accounts;

    // Set the staked amount for a given account
    function _setStakedAmount(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];

        if (!account.stakedTokens.exists(token_) && amount_ != 0) account.stakedTokens.insert(token_);
        else if (account.stakedTokens.exists(token_) && amount_ == 0) account.stakedTokens.remove(token_);

        _setTotalStaked(token_, totalStaked(token_).sub(account.stakedAmount[token_]).add(amount_));

        if (account.isStaking == 0 && amount_ > 0) account.initialStakeEpoch = epochId;
        account.isStaking = account.isStaking.add(amount_);
        account.stakedEpoch[token_] = epochId;
        account.stakedAmount[token_] = amount_;
    }

    // Get the staked amount for a given account
    function _stakedAmount(address token_, address account_) internal view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.stakedAmount[token_];
    }

    // Set the staked epoch for a given account
    function _setStakedEpoch(
        address token_,
        uint256 epochId_,
        address account_
    ) internal {
        Account storage account = _accounts[account_];
        account.stakedEpoch[token_] = epochId_;
    }

    // Get the staked epoch for a given account
    function _stakedEpoch(address token_, address account_) internal view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.stakedEpoch[token_];
    }

    // Set the initial stake epoch for a given account
    function _setInitialStakeEpoch(uint256 epochId_, address account_) internal {
        Account storage account = _accounts[account_];
        account.initialStakeEpoch = epochId_;
    }

    // Get the initial stake epoch for a given account
    function _initialStakeEpoch(address account_) internal view returns (uint256) {
        Account storage account = _accounts[account_];
        return account.initialStakeEpoch;
    }

    // Get the list of staked tokens for a given account
    function _stakedTokensList(address account_) internal view returns (address[] memory) {
        Account storage account = _accounts[account_];
        return account.stakedTokens.iterable();
    }
}
