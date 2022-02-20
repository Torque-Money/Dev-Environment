//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {TreasurerDistributor} from "./TreasurerDistributor.sol";
import {TreasurerWrappedStake} from "./TreasurerWrappedStake.sol";

abstract contract TreasurerStake is TreasurerWrappedStake {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // NOTE Should I move the requirement for the oustanding tokens somewhere that suits it better ?

    // Stake tokens
    function stake(address token_, uint256 amount_) external onlyApprovedStakeToken(token_) {
        rebase();
        _wrappedStakeUpdate(_msgSender());

        require(amount_ > 0, "TreasurerStake: Stake amount must be greater than 0");

        IERC20Upgradeable(token_).safeTransferFrom(_msgSender(), address(this), amount_);
        _setStaked(token_, staked(token_, _msgSender()).add(amount_), _msgSender());

        emit Stake(_msgSender(), token_, amount_);
    }

    // Unstake tokens
    function unstake(address token_, uint256 amount_) external onlyStakeToken(token_) {
        _wrappedStakeUpdate(_msgSender());

        require(amount_ > 0, "TreasurerStake: Unstake amount must be greater than 0");
        require(amount_ <= staked(token_, _msgSender()), "TreasurerStake: Cannot unstake more than available amount");

        IERC20Upgradeable(token_).safeTransfer(_msgSender(), amount_);
        _setStaked(token_, staked(token_, _msgSender()).sub(amount_), _msgSender());
        require(
            token_ != reserveToken || outstandingWrappedTokens(_msgSender()) <= allowedMintedTokens(_msgSender()),
            "TreasurerStake: Outstanding wrapped tokens cannot exceed allowed minted tokens"
        );

        emit Unstake(_msgSender(), token_, amount_);
    }

    event Stake(address indexed account, address token, uint256 amount);
    event Unstake(address indexed account, address token, uint256 amount);
}
