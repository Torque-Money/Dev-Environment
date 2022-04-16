//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IStrategy} from "../../interfaces/lens/strategy/IStrategy.sol";
import {Registry} from "../../utils/Registry.sol";
import {Emergency} from "../../utils/Emergency.sol";

contract StrategyController is Initializable, AccessControlUpgradeable, Registry, Emergency {}
