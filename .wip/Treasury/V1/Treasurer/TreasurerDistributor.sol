//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {ReserveToken} from "../Token/ReserveToken.sol";
import {Treasury} from "../Treasury.sol";
import {TreasurerEpoch} from "./TreasurerEpoch.sol";
import {TreasurerPool} from "./TreasurerPool.sol";
import {TreasurerDistributorCore} from "./TreasurerDistributorCore.sol";

abstract contract TreasurerDistributor is TreasurerEpoch, TreasurerDistributorCore, TreasurerPool {
    using SafeMathUpgradeable for uint256;

    // Get the amount of reserve tokens redeemable for the given epoch
    function distributedReserveTokenAmount(
        address token_,
        uint256 amount_,
        uint256 epochId_
    ) public view returns (uint256) {
        return amount_.mul(_epochRemainingReserveTokens(token_, epochId_)).div(_epochRemainingAmountStaked(token_, epochId_));
    }

    // Withdraw tokens from the epoch
    function _distributeReserveToken(
        address token_,
        uint256 amount_,
        uint256 epochId_
    ) internal returns (uint256) {
        uint256 distributeAmount = distributedReserveTokenAmount(token_, amount_, epochId_);

        _setEpochRemainingAmountStaked(token_, _epochRemainingAmountStaked(token_, epochId_).sub(amount_), epochId_);
        _setEpochRemainingReserveTokens(token_, _epochRemainingReserveTokens(token_, epochId_).sub(distributeAmount), epochId_);

        return distributeAmount;
    }

    // Calculate the amount of reserve assets that can be minted
    function mintableReserveTokens() public view returns (uint256) {
        uint256 tvl = Treasury(treasury).tvl();
        uint256 totalSupply = ReserveToken(reserveToken).totalSupply();

        if (totalSupply != 0) {
            (uint256 reserveTokenBackingDecayPercentNumerator, uint256 reserveTokenBackingDecayPercentDenominator) = reserveTokenBackingDecayPercent();

            if (tvl > maxHistoricalTreasuryValue)
                return
                    totalSupply.mul(tvl.sub(maxHistoricalTreasuryValue)).mul(reserveTokenBackingDecayPercentNumerator).div(maxHistoricalTreasuryValue).div(
                        reserveTokenBackingDecayPercentDenominator
                    );
            else return 0;
        } else return resetTotalSupply;
    }

    // Check if a rebase is available
    function isRebaseAvailable() public view returns (bool) {
        if (mintableReserveTokens() == 0) return false;

        if (epochId == 0) return true;
        else return epochTime(epochId.sub(1)).add(rebaseCooldown) <= block.timestamp;
    }

    // Rebase tokens to the appropriate limbo allocations
    function rebase() public {
        require(isRebaseAvailable(), "TreasurerDistributor: Rebase is not available");

        _setEpochTime(block.timestamp, epochId);

        uint256 mintAvailable = mintableReserveTokens();

        ReserveToken(reserveToken).mint(address(this), mintAvailable);

        emit Rebase(mintAvailable, epochId);

        uint256 totalApprovedStakeValue = _totalApprovedStakedValue();
        (uint256 reserveTokenDistributionPercentNumerator, uint256 reserveTokenDistributionPercentDenominator) = reserveTokenDistributionPercent();

        address[] memory approvedStakeTokens = _approvedStakeTokensList();
        for (uint256 i = 0; i < approvedStakeTokens.length; i++) {
            _setEpochRemainingAmountStaked(approvedStakeTokens[i], totalStaked(approvedStakeTokens[i]), epochId);
            _setEpochTotalAmountStaked(approvedStakeTokens[i], totalStaked(approvedStakeTokens[i]), epochId);

            uint256 allocation = mintAvailable
                .mul(_totalApprovedStakedValue(approvedStakeTokens[i]))
                .mul(reserveTokenDistributionPercentNumerator)
                .div(totalApprovedStakeValue)
                .div(reserveTokenDistributionPercentDenominator);

            _setEpochRemainingReserveTokens(approvedStakeTokens[i], allocation, epochId);
            _setEpochTotalMintedReserveTokens(epochTotalMintedReserveTokens(epochId).add(allocation), epochId);
        }

        _setEpochRemainingAmountStaked(reserveToken, totalStaked(reserveToken), epochId);
        _setEpochTotalAmountStaked(reserveToken, totalStaked(reserveToken), epochId);
        _setEpochRemainingReserveTokens(reserveToken, mintAvailable.sub(epochTotalMintedReserveTokens(epochId)), epochId);
        _setEpochTotalMintedReserveTokens(mintAvailable, epochId);

        epochId = epochId.add(1);
        _setTotalStaked(reserveToken, totalStaked(reserveToken).add(mintAvailable));

        _setMaxHistoricalTreasuryValue(Treasury(treasury).tvl());
    }

    event Rebase(uint256 amount, uint256 epochId);
}
