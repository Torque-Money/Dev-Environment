//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {ISupportsToken} from "../../interfaces/utils/ISupportsToken.sol";
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
    IUniswapV2Factory public uniFactory;
    IBeefyVaultV6 public beVault;

    uint256 private apy;

    function initialize(
        IERC20[] memory token,
        uint256 initialAPY,
        IUniswapV2Router02 _uniRouter,
        IUniswapV2Factory _uniFactory,
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

        apy = initialAPY;

        uniRouter = _uniRouter;
        uniFactory = _uniFactory;
        beVault = _beVault;
    }

    function depositAllIntoStrategy() private {
        // Deposit assets into LP tokens
        IERC20 token0 = tokenByIndex(0);
        IERC20 token1 = tokenByIndex(1);
        uint256 amountADesired = token0.balanceOf(address(this));
        uint256 amountBDesired = token1.balanceOf(address(this));

        token0.safeApprove(address(uniRouter), amountADesired);
        token1.safeApprove(address(uniRouter), amountBDesired);

        uniRouter.addLiquidity(address(token0), address(token1), amountADesired, amountBDesired, 1, 1, address(this), block.timestamp);

        // Deposit into Beefy vault
        IERC20 LPToken = beVault.want();
        uint256 LPTokenBalance = LPToken.balanceOf(address(this));

        LPToken.safeApprove(address(beVault), LPTokenBalance);

        beVault.deposit(LPTokenBalance);
    }

    function withdrawAllFromStrategy() private {
        // Withdraw from Beefy vault
        beVault.withdrawAll();

        // Redeem LP tokens
        address token0 = address(tokenByIndex(0));
        address token1 = address(tokenByIndex(1));

        IERC20 pair = IERC20(uniFactory.getPair(token0, token1));
        uint256 pairBalance = pair.balanceOf(address(this));

        pair.safeApprove(address(uniFactory), pairBalance);

        uniRouter.removeLiquidity(token0, token1, pairBalance, 1, 1, address(this), block.timestamp);
    }

    function deposit(uint256[] calldata amount) external onlyTokenAmount(amount) onlyRole(STRATEGY_CONTROLLER_ROLE) {
        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransferFrom(_msgSender(), address(this), amount[i]);

        depositAllIntoStrategy();
    }

    function withdraw(uint256[] calldata amount) external onlyTokenAmount(amount) onlyRole(STRATEGY_CONTROLLER_ROLE) {
        withdrawAllFromStrategy();

        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransfer(_msgSender(), amount[i]);

        depositAllIntoStrategy();
    }

    function APY() external view returns (uint256 apy, uint256 decimals) {
        // **** Return the APY
    }

    function updateAPY(uint256 apy, uint256 decimals) external onlyRole(STRATEGY_CONTROLLER_ROLE) {
        // **** Update the APY
    }

    function balance(IERC20 token) public view override(ISupportsToken, SupportsToken) onlySupportedToken(token) returns (uint256 amount) {
        // **** Needs to get the underlying LP amount and return the balance for each
        // **** I need to be able to calculate this based off of the current LP deposit and the current share price from the BE token ???
        // **** beVault requires me to get the price per share (with its own non-diclosed decimal) and convert it myself???
    }

    function inCaseTokensGetStuck(IERC20 token, uint256 amount) public override onlyRole(STRATEGY_ADMIN_ROLE) {
        super.inCaseTokensGetStuck(token, amount);
    }
}
