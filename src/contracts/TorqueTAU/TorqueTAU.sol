//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract TorqueTAU is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{
    bytes32 public TOKEN_ADMIN_ROLE;
    bytes32 public TOKEN_MINTER_ROLE;
    bytes32 public TOKEN_BURNER_ROLE;

    function initialize(uint256 initialSupply_) external initializer {
        __ERC20_init("Torque TAU", "TAU");
        __AccessControlEnumerable_init();

        _mint(_msgSender(), initialSupply_);

        TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");
        _setRoleAdmin(TOKEN_ADMIN_ROLE, TOKEN_ADMIN_ROLE);
        _grantRole(TOKEN_ADMIN_ROLE, _msgSender());

        TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER_ROLE");
        _setRoleAdmin(TOKEN_MINTER_ROLE, TOKEN_ADMIN_ROLE);

        TOKEN_BURNER_ROLE = keccak256("TOKEN_BURNER_ROLE");
        _setRoleAdmin(TOKEN_BURNER_ROLE, TOKEN_ADMIN_ROLE);
    }

    /**
     *  Mint tokens to a user
     */
    function mint(address account, uint256 amount)
        external
        onlyRole(TOKEN_MINTER_ROLE)
    {
        _mint(account, amount);
    }

    /**
     *  Burn tokens from a user
     */
    function burn(address account, uint256 amount) external onlyRole(TOKEN_BURNER_ROLE) {
        _burn(account, amount);
    }
}
