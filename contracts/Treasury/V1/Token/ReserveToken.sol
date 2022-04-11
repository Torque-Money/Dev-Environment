//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ReserveToken is Initializable, AccessControlUpgradeable, ERC20Upgradeable {
    bytes32 public constant TOKEN_ADMIN = keccak256("TOKEN_ADMIN_ROLE");
    bytes32 public constant TOKEN_APPROVED = keccak256("TOKEN_APPROVED_ROLE");

    function initializeReserveToken(string memory name_, string memory symbol_) external initializer {
        __AccessControl_init();
        __ERC20_init(name_, symbol_);

        _setRoleAdmin(TOKEN_ADMIN, TOKEN_ADMIN);
        _setRoleAdmin(TOKEN_APPROVED, TOKEN_ADMIN);
        _grantRole(TOKEN_APPROVED, _msgSender());
    }

    // Mint new tokens
    function mint(address to_, uint256 amount_) external onlyRole(TOKEN_APPROVED) {
        _mint(to_, amount_);
    }

    // Burn tokens
    function burn(address account_, uint256 amount_) external onlyRole(TOKEN_APPROVED) {
        _burn(account_, amount_);
    }
}
