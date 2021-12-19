//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using SafeMath for uint256;

    uint256 public numYields;
    uint256 public yieldSlashRate;
    uint256 public yieldReward;

    constructor(uint256 _initialSupply, uint256 _yieldSlashRate, uint256 _yieldReward) ERC20("Wabbit", "WBT") ERC20Permit("WBT") {
        yieldSlashRate = _yieldSlashRate;
        yieldReward = _yieldReward;
        _mint(owner(), _initialSupply);
    }

    function setYieldSlashRate(uint256 _yieldSlashRate) external onlyOwner { yieldSlashRate = _yieldSlashRate; }

    function setYieldReward(uint256 _yieldReward) external onlyOwner { yieldReward = _yieldReward; }

    function yield(address _account) external onlyOwner {
        uint256 slash = numYields.div(yieldSlashRate);
        if (slash == 0) slash = 1;
        uint256 amount = yieldReward.div(slash);
        _mint(_account, amount);
        numYields = numYields.add(1);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}