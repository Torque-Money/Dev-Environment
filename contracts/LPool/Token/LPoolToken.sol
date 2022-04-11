//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract LPoolToken is Initializable, AccessControlUpgradeable, ERC20Upgradeable, ERC20PausableUpgradeable {
    bytes32 public TOKEN_ADMIN;

    function initialize(string memory name_, string memory symbol_) external initializer {
        __AccessControl_init();
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();

        TOKEN_ADMIN = keccak256("TOKEN_ADMIN_ROLE");
        _setRoleAdmin(TOKEN_ADMIN, TOKEN_ADMIN);
        _grantRole(TOKEN_ADMIN, _msgSender());
    }

    function mint(address account_, uint256 amount_) external onlyRole(TOKEN_ADMIN) {
        _mint(account_, amount_);
    }

    function burn(address account_, uint256 amount_) external onlyRole(TOKEN_ADMIN) {
        _burn(account_, amount_);
    }

    // Pause the contract
    function pause() external onlyRole(TOKEN_ADMIN) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(TOKEN_ADMIN) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, amount_);
    }
}
