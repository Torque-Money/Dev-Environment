//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {BaseVaultETHWrapper} from "./BaseVaultETHWrapper.sol";

import {Vault} from "../../../../src/lens/vault/Vault.sol";
import {Config} from "../../helpers/Config.sol";

contract DepositRedeemTest is BaseVaultETHWrapper {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for Vault;

    // Test a regular deposit and redeem.
    function testDepositRedeem() public useFunds(vm) {
        // Calculate initial balances of ERC20 and ETH
        uint256[] memory initialBalance = new uint256[](_token.length);
        for (uint256 i = 0; i < _token.length; i++) initialBalance[i] = _token[i].balanceOf(address(this));

        uint256 initialETH = address(this).balance;

        // Check that the estimated shares matches the allocated shares
        uint256 ethDeposit;
        for (uint256 i = 0; i < _token.length; i++)
            if (address(_token[i]) == address(Config.getWETH())) {
                ethDeposit = _tokenAmount[i];
                break;
            }

        uint256 shares = _wrapper.deposit{value: ethDeposit}(_vault, _tokenAmount);

        // Check balances have been updated
        for (uint256 i = 0; i < _token.length; i++)
            if (address(_token[i]) != address(Config.getWETH())) assertEq(_token[i].balanceOf(address(this)), initialBalance[i].sub(_tokenAmount[i]));
            else assertEq(address(this).balance, initialETH.sub(ethDeposit));

        assertEq(_vault.balanceOf(address(this)), shares);

        // Check that the required amounts are output
        _vault.safeIncreaseAllowance(address(_wrapper), shares);
        uint256[] memory out = _wrapper.redeem(_vault, shares);

        for (uint256 i = 0; i < _token.length; i++)
            if (address(_token[i]) != address(Config.getWETH())) _assertApproxEq(_token[i].balanceOf(address(this)), initialBalance[i]);
            else _assertApproxEq(address(this).balance, initialETH);

        // Check the the correct shares are removed
        assertEq(_vault.balanceOf(address(this)), 0);
    }
}
