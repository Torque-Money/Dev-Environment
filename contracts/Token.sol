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
    uint256 public baseYieldReward;

    IYieldApproved public yieldApproved;

    constructor(uint256 initialSupply_, uint256 yieldSlashRate_, uint256 baseYieldReward_, IYieldApproved yieldApproved_) ERC20("Wabbit", "WBT") ERC20Permit("WBT") {
        yieldSlashRate = yieldSlashRate_;
        baseYieldReward = baseYieldReward_;
        yieldApproved = yieldApproved_;

        _mint(owner(), initialSupply_);
    }

    /** @dev Set the yield slash rate */
    function setYieldSlashRate(uint256 _yieldSlashRate) external onlyOwner { yieldSlashRate = _yieldSlashRate; }

    /** @dev Set the yield reward */
    function setBaseYieldReward(uint256 _baseYieldReward) external onlyOwner { baseYieldReward = _baseYieldReward; }

    /** @dev Set the yield approval function */
    function setYieldApproved(IYieldApproved _yieldApproved) external onlyOwner { yieldApproved = _yieldApproved; }

    /** @dev Get the current yield reward */
    function currentYieldReward() public view returns (uint256) {
        uint256 slash = numYields.div(yieldSlashRate);
        if (slash == 0) slash = 1;

        return baseYieldReward.div(slash);
    }

    /** @dev Yield new tokens as a reward to the caller if approved to do so by the yield function */
    function yield(IERC20 _token) external {
        // Make sure the yield has been approved first
        address account = _msgSender();
        (uint256 stake, uint256 borrowed) = yieldApproved.yieldApproved(account, _token);
        require(stake > 0 || borrowed > 0, "Account has not staked or borrowed this token to earn a yield on it");

        uint256 reward = currentYieldReward();
        _mint(account, reward);
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