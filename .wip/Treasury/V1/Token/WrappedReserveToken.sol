//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

contract WrappedReserveToken is Initializable, OwnableUpgradeable, ERC20Upgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable {
    function initializeWrappedReserveToken(string memory name_, string memory symbol_) external initializer {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
    }

    // Mint new tokens
    function mint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    // Burn tokens
    function burn(address account_, uint256 amount_) external onlyOwner {
        _burn(account_, amount_);
    }

    // Disable transfers
    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert("WrappedReserveToken: Transfers are disabled");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }
}
