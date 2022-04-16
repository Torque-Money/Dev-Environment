//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

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

    uint256 private twaapy;

    function initialize(
        IERC20[] memory token,
        uint256 initialAPY,
        IUniswapV2Router02 _uniRouter,
        IUniswapV2Factory _uniFactory,
        IBeefyVaultV6 _beVault
    ) external initializer {
        __AccessControl_init();
        __SupportsToken_init(token, 2);
        __Emergency_init();

        STRATEGY_ADMIN_ROLE = keccak256("STRATEGY_ADMIN_ROLE");
        _setRoleAdmin(STRATEGY_ADMIN_ROLE, STRATEGY_ADMIN_ROLE);
        _grantRole(STRATEGY_ADMIN_ROLE, _msgSender());

        STRATEGY_CONTROLLER_ROLE = keccak256("STRATEGY_CONTROLLER_ROLE");
        _setRoleAdmin(STRATEGY_CONTROLLER_ROLE, STRATEGY_ADMIN_ROLE);
        _grantRole(STRATEGY_CONTROLLER_ROLE, address(this));

        twaapy = initialAPY;

        uniRouter = _uniRouter;
        uniFactory = _uniFactory;
        beVault = _beVault;
    }

    function _injectAllIntoStrategy() private {
        // Deposit assets into LP tokens
        IERC20 token0 = tokenByIndex(0);
        IERC20 token1 = tokenByIndex(1);
        uint256 amountADesired = token0.balanceOf(address(this));
        uint256 amountBDesired = token1.balanceOf(address(this));

        token0.safeApprove(address(uniRouter), amountADesired);
        token1.safeApprove(address(uniRouter), amountBDesired);

        uniRouter.addLiquidity(address(token0), address(token1), amountADesired, amountBDesired, 1, 1, address(this), block.timestamp);

        // Deposit into Beefy vault
        IERC20 pair = IERC20(uniFactory.getPair(address(token0), address(token1)));
        uint256 pairBalance = pair.balanceOf(address(this));

        pair.safeApprove(address(beVault), pairBalance);

        beVault.depositAll();
    }

    function _ejectAllFromStrategy() private {
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

    function _deposit(uint256[] memory amount) private {
        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransferFrom(_msgSender(), address(this), amount[i]);

        _injectAllIntoStrategy();
    }

    function deposit(uint256[] memory amount) external onlyTokenAmount(amount) onlyRole(STRATEGY_CONTROLLER_ROLE) {
        _deposit(amount);

        emit Deposit(_msgSender(), amount);
    }

    function depositAll() external onlyRole(STRATEGY_CONTROLLER_ROLE) {
        uint256[] memory amount = new uint256[](tokenCount());
        for (uint256 i = 0; i < tokenCount(); i++) amount[i] = tokenByIndex(i).balanceOf(_msgSender());

        _deposit(amount);

        emit DepositAll(_msgSender());
    }

    function _withdraw(uint256[] memory amount) private {
        _ejectAllFromStrategy();

        for (uint256 i = 0; i < tokenCount(); i++) tokenByIndex(i).safeTransfer(_msgSender(), amount[i]);
    }

    function withdraw(uint256[] memory amount) external onlyTokenAmount(amount) onlyRole(STRATEGY_CONTROLLER_ROLE) {
        _withdraw(amount);
        _injectAllIntoStrategy();

        emit Withdraw(_msgSender(), amount);
    }

    function withdrawAll() external onlyRole(STRATEGY_CONTROLLER_ROLE) {
        uint256[] memory amount = new uint256[](tokenCount());
        for (uint256 i = 0; i < tokenCount(); i++) amount[i] = tokenByIndex(i).balanceOf(_msgSender());

        _withdraw(amount);

        emit WithdrawAll(_msgSender());
    }

    function APY() external view returns (uint256 apy, uint256 decimals) {
        return (twaapy, 1e4);
    }

    function updateAPY(uint256 apy) external onlyRole(STRATEGY_CONTROLLER_ROLE) {
        uint256 EMA_WEIGHT_PERCENT = 70;

        uint256 temp = twaapy.mul(uint256(100).sub(EMA_WEIGHT_PERCENT).div(100));
        temp = temp.add(apy.mul(EMA_WEIGHT_PERCENT).div(100));

        twaapy = temp;
    }

    function balance(IERC20 token) public view override(ISupportsToken, SupportsToken) onlySupportedToken(token) returns (uint256 amount) {
        // Get LP tokens owed by beVault
        uint256 SHARE_BASE = 1e18;
        uint256 LPAmount = beVault.getPricePerFullShare().mul(IERC20(address(beVault)).balanceOf(address(this))).div(SHARE_BASE);

        // Get the allocation of the specified balance
        IUniswapV2Pair pair = IUniswapV2Pair(uniFactory.getPair(address(tokenByIndex(0)), address(tokenByIndex(1))));

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        uint256 reserve;
        if (pair.token0() == address(token)) reserve = reserve0;
        else reserve = reserve1;

        return LPAmount.mul(reserve).div(pair.totalSupply()).add(token.balanceOf(address(this)));
    }
}
