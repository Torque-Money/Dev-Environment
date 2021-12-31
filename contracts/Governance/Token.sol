//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes, Ownable {
    constructor(uint256 initialSupply_) ERC20("Torque", "TAU") ERC20Permit("TAU") {
        _mint(owner(), initialSupply_);
    }

    function _afterTokenTransfer(address _from, address _to, uint256 _amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(_from, _to, _amount);
    }

    function _mint(address _to, uint256 _amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(_to, _amount);
    }

    function _burn(address _account, uint256 _amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(_account, _amount);
    }
}