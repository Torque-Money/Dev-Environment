//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes, AccessControl {
    bytes32 public constant TOKEN_ADMIN = keccak256("TOKEN_ADMIN_ROLE");
    bytes32 public constant TOKEN_CONTROL = keccak256("TOKEN_CONTROL_ROLE");

    constructor(uint256 initialSupply_) ERC20("Torque", "TAU") ERC20Permit("TAU") {
        _setRoleAdmin(TOKEN_ADMIN, TOKEN_ADMIN);
        _setRoleAdmin(TOKEN_CONTROL, TOKEN_ADMIN);
        _grantRole(TOKEN_ADMIN, _msgSender());
        _mint(_msgSender(), initialSupply_);
    }

    function mint(address to_, uint256 amount_) external onlyRole(TOKEN_CONTROL) {
        _mint(to_, amount_);
    }

    function burn(address account_, uint256 amount_) external onlyRole(TOKEN_CONTROL) {
        _burn(account_, amount_);
    }

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(_from, _to, _amount);
    }

    function _mint(address _to, uint256 _amount) internal override(ERC20, ERC20Votes) {
        super._mint(_to, _amount);
    }

    function _burn(address _account, uint256 _amount) internal override(ERC20, ERC20Votes) {
        super._burn(_account, _amount);
    }
}
