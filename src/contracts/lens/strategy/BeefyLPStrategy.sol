//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {SupportsToken} from "../../utils/SupportsToken.sol";
import {Emergency} from "../../utils/Emergency.sol";

import {IBeefyVaultV6} from "../../interfaces/lib/IBeefyVaultV6.sol";

// This strategy will take two tokens and will deposit them into the correct LP pair for the given pool.
// It will then take the LP token and deposit it into a Beefy vault.

contract BeefyLPStrategy is Initializable, AccessControlUpgradeable, IStrategy, SupportsToken, Emergency {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public STRATEGY_ADMIN_ROLE;
    bytes32 public STRATEGY_CONTROLLER_ROLE;

    IUniswapV2Router02 public uniRouter;
    IBeefyVaultV6 public beVault;

    function initialize(
        IERC20[] memory token,
        IUniswapV2Router02 _uniRouter,
        IBeefyVaultV6 _beVault
    ) external initializer {
        __AccessControl_init();
        __SupportsToken_init(token, 2);

        STRATEGY_ADMIN_ROLE = keccak256("STRATEGY_ADMIN_ROLE");
        _setRoleAdmin(STRATEGY_ADMIN_ROLE, STRATEGY_ADMIN_ROLE);
        _grantRole(STRATEGY_ADMIN_ROLE, _msgSender());

        STRATEGY_CONTROLLER_ROLE = keccak256("STRATEGY_CONTROLLER_ROLE");
        _setRoleAdmin(STRATEGY_CONTROLLER_ROLE, STRATEGY_ADMIN_ROLE);
        _grantRole(STRATEGY_CONTROLLER_ROLE, address(this));

        uniRouter = _uniRouter;
        beVault = _beVault;
    }
}
