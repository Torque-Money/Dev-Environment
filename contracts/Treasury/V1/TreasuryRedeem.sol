//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IOracle} from "../../Oracle/IOracle.sol";
import {TreasuryLiquidity} from "./TreasuryLiquidity.sol";
import {ReserveToken} from "./Token/ReserveToken.sol";

abstract contract TreasuryRedeem is TreasuryLiquidity {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Get the amount of the given reserve treasury for the given number of reserve tokens
    function redeemTreasuryTokenAmount(uint256 amount_, address token_) public view onlyApprovedTreasuryAsset(token_) returns (uint256) {
        uint256 _tvl = tvl();
        uint256 _totalSupply = ReserveToken(reserveToken).totalSupply();

        uint256 redeemPrice = amount_.mul(_tvl).div(_totalSupply);
        uint256 redeemAmount = IOracle(oracle).amountMin(token_, redeemPrice);

        return redeemAmount;
    }

    // Redeem tokens for treasury assets
    function redeemReserveToken(uint256 amount_, address token_) external onlyApprovedTreasuryAsset(token_) returns (uint256) {
        uint256 _redeemAmount = redeemTreasuryTokenAmount(amount_, token_);

        ReserveToken(reserveToken).burn(_msgSender(), amount_);
        IERC20Upgradeable(token_).safeTransfer(_msgSender(), _redeemAmount);

        emit RedeemReserveToken(_msgSender(), amount_, token_, _redeemAmount);

        return _redeemAmount;
    }

    event RedeemReserveToken(address indexed account, uint256 reserveTokenAmount, address treasuryAsset, uint256 treasuryAssetAmount);
}
