//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IEmergency} from "../interfaces/utils/IEmergency.sol";

contract Emergency is Initializable, AccessControlUpgradeable, IEmergency {
    using SafeERC20 for IERC20;

    bytes32 public EMERGENCY_ADMIN_ROLE;

    function __Emergency_init() internal onlyInitializing {
        __AccessControl_init();

        __Emergency_init_unchained();
    }

    function __Emergency_init_unchained() internal onlyInitializing {
        EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE");
        _setRoleAdmin(EMERGENCY_ADMIN_ROLE, EMERGENCY_ADMIN_ROLE);
        _grantRole(EMERGENCY_ADMIN_ROLE, _msgSender());
    }

    function inCaseTokensGetStuck(IERC20 token, uint256 amount) public virtual override onlyRole(EMERGENCY_ADMIN_ROLE) {
        if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) payable(msg.sender).transfer(amount);
        else token.safeTransfer(msg.sender, amount);
    }
}
