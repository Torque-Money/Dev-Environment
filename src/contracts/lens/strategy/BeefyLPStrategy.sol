//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {SupportsToken} from "../../utils/SupportsToken.sol";
import {Emergency} from "../../utils/Emergency.sol";

import {IBeefyVaultV6} from "../../interfaces/lib/IBeefyVaultV6.sol";

// This strategy will take two tokens and will deposit them into the correct LP pair for the given pool.
// It will then take the LP token and deposit it into a Beefy vault.

contract BeefyLPStrategy is IStrategy, SupportsToken, Emergency {

}
