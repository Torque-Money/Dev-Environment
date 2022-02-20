//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {TreasurerAccountCore} from "./TreasurerAccountCore.sol";

abstract contract TreasurerAccount is TreasurerAccountCore {
    using SafeMathUpgradeable for uint256;

    // Get the accumulated rewards for the account
    function _accumulatedReserveTokens(address account_) internal view returns (uint256) {
        uint256 accumulated = 0;

        if (epochId != _initialStakeEpoch(account_)) {
            address[] memory stakedTokens = _stakedTokensList(account_);
            uint256[] memory earnedReserveTokens = new uint256[](epochId.sub(_initialStakeEpoch(account_)));

            for (uint256 i = 0; i < stakedTokens.length; i++)
                for (uint256 j = _stakedEpoch(stakedTokens[i], account_); j < epochId; j++)
                    earnedReserveTokens[j.sub(_initialStakeEpoch(account_))] = earnedReserveTokens[j.sub(_initialStakeEpoch(account_))].add(
                        distributedReserveTokenAmount(stakedTokens[i], _stakedAmount(stakedTokens[i], account_), j)
                    );

            uint256 compoundAccumulation = earnedReserveTokens[0];
            uint256 compounded = 0;
            for (uint256 i = 1; i < earnedReserveTokens.length; i++) {
                compounded = compounded.add(distributedReserveTokenAmount(reserveToken, compoundAccumulation.add(compounded), i));
                compoundAccumulation = compoundAccumulation.add(earnedReserveTokens[i]);
            }

            accumulated = accumulated.add(compounded);
        }

        return accumulated;
    }

    // NOTE **** this should be modularized so it doesnt need to be an exact copy of the function above
    // Update the accumulated reserve tokens for the account into their staked pool
    function _updateAccumulatedReserveTokens(address account_) internal returns (uint256) {
        uint256 accumulated = 0;

        if (epochId != _initialStakeEpoch(account_)) {
            address[] memory stakedTokens = _stakedTokensList(account_);
            uint256[] memory earnedReserveTokens = new uint256[](epochId.sub(_initialStakeEpoch(account_)));

            for (uint256 i = 0; i < stakedTokens.length; i++) {
                for (uint256 j = _stakedEpoch(stakedTokens[i], account_); j < epochId; j++)
                    earnedReserveTokens[j.sub(_initialStakeEpoch(account_))] = earnedReserveTokens[j.sub(_initialStakeEpoch(account_))].add(
                        _distributeReserveToken(stakedTokens[i], _stakedAmount(stakedTokens[i], account_), j)
                    );
                _setStakedEpoch(stakedTokens[i], epochId, account_);
            }
            _setInitialStakeEpoch(epochId, account_);

            uint256 compoundAccumulation = earnedReserveTokens[0];
            uint256 compounded = 0;
            for (uint256 i = 1; i < earnedReserveTokens.length; i++) {
                compounded = compounded.add(_distributeReserveToken(reserveToken, compoundAccumulation.add(compounded), i));
                compoundAccumulation = compoundAccumulation.add(earnedReserveTokens[i]);
            }

            accumulated = accumulated.add(compounded);
            _setStakedAmount(reserveToken, _stakedAmount(reserveToken, account_).add(accumulated), account_);
        }

        return accumulated;
    }

    // Set the amount staked for a given asset
    function _setStaked(
        address token_,
        uint256 amount_,
        address account_
    ) internal {
        _updateAccumulatedReserveTokens(account_);
        _setStakedAmount(token_, amount_, account_);
    }

    // Get the staked amount for a given asset
    function staked(address token_, address account_) public view onlyStakeToken(token_) returns (uint256) {
        uint256 amount = _stakedAmount(token_, account_);
        if (token_ == reserveToken) amount = amount.add(_accumulatedReserveTokens(account_));

        return amount;
    }
}
