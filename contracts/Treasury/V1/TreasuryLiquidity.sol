//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IOracle} from "../../Oracle/IOracle.sol";
import {TreasuryApproved} from "./TreasuryApproved.sol";

abstract contract TreasuryLiquidity is TreasuryApproved {
    using SafeMathUpgradeable for uint256;

    // Get the total amount of a given asset locked in the treasury
    function totalAmountLocked(address token_) public view onlyApprovedTreasuryAsset(token_) returns (uint256) {
        return IERC20Upgradeable(token_).balanceOf(address(this));
    }

    // Get the total value of an asset locked in the treasury
    function tvl(address token_) public view onlyApprovedTreasuryAsset(token_) returns (uint256) {
        return IOracle(oracle).priceMax(token_, totalAmountLocked(token_));
    }

    // Get the total value of all assets locked in the treasury
    function tvl() public view returns (uint256) {
        address[] memory approvedList = _approvedTreasuryAssetsList();
        uint256 totalValue = 0;

        for (uint256 i = 0; i < approvedList.length; i++) totalValue = totalValue.add(tvl(approvedList[i]));

        return totalValue;
    }
}
