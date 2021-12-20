//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IYieldApproved.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using SafeMath for uint256;

    uint256 public numYields;
    uint256 public yieldSlashRate;
    uint256 public yieldReward;

    IYieldApproved public yieldApproved;

    constructor(uint256 initialSupply_, uint256 yieldSlashRate_, uint256 yieldReward_, IYieldApproved yieldApproved_) ERC20("Wabbit", "WBT") ERC20Permit("WBT") {
        yieldSlashRate = yieldSlashRate_;
        yieldReward = yieldReward_;
        yieldApproved = yieldApproved_;

        _mint(owner(), initialSupply_);
    }

    function setYieldSlashRate(uint256 _yieldSlashRate) external onlyOwner { yieldSlashRate = _yieldSlashRate; }

    function setYieldReward(uint256 _yieldReward) external onlyOwner { yieldReward = _yieldReward; }

    function setYieldApproved(IYieldApproved _yieldApproved) external onlyOwner { yieldApproved = _yieldApproved; }

    function yield(address _account) external onlyOwner {
        require(yieldApproved.yieldApproved(_account), "Account is not approved to yield tokens");

        uint256 slash = numYields.div(yieldSlashRate);
        if (slash == 0) slash = 1;

        uint256 amount = yieldReward.div(slash);

        _mint(_account, amount);
        numYields = numYields.add(1);
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