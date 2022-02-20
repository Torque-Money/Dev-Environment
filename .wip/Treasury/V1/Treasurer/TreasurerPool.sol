//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IOracle} from "../../../Oracle/IOracle.sol";
import {TreasurerApproved} from "./TreasurerApproved.sol";

abstract contract TreasurerPool is TreasurerApproved {
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) private _totalStaked;

    // Set the amount staked of a given asset
    function _setTotalStaked(address token_, uint256 amount_) internal {
        _totalStaked[token_] = amount_;
    }

    // Get the total amount staked of a given asset
    function totalStaked(address token_) public view onlyStakeToken(token_) returns (uint256) {
        return _totalStaked[token_];
    }

    // Get the staked value for a staked asset
    function _totalApprovedStakedValue(address token_) internal view returns (uint256) {
        return IOracle(oracle).priceMax(token_, totalStaked(token_));
    }

    // Get the staked value for all approved stake assets
    function _totalApprovedStakedValue() internal view returns (uint256) {
        uint256 total = 0;
        address[] memory tokens = _approvedStakeTokensList();

        for (uint256 i = 0; i < tokens.length; i++) total = total.add(_totalApprovedStakedValue(tokens[i]));

        return total;
    }
}
