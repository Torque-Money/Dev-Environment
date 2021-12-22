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

    // **** Perhaps they should get the same amount back that they pay in interest

    IYieldApproved public yieldApproved;

    uint256 public yieldSlashRate;
    uint256 public maxYieldRate;

    mapping(IERC20 => uint256) private NumYields;

    constructor(uint256 initialSupply_, uint256 yieldSlashRate_, uint256 maxYieldRate_, IYieldApproved yieldApproved_) ERC20("Wabbit", "WBT") ERC20Permit("WBT") {
        yieldSlashRate = yieldSlashRate_;
        yieldApproved = yieldApproved_;
        maxYieldRate = maxYieldRate_;

        _mint(owner(), initialSupply_);
    }

    /** @dev Set the yield slash rate */
    function setYieldSlashRate(uint256 _yieldSlashRate) external onlyOwner {
        yieldSlashRate = _yieldSlashRate;
    }

    /** @dev Set the yield approval function */
    function setYieldApproved(IYieldApproved _yieldApproved) external onlyOwner {
        yieldApproved = _yieldApproved;
    }

    /** @dev Set the max yield rate */
    function setMaxYieldRate(uint256 _maxYieldRate) external onlyOwner {
        maxYieldRate = _maxYieldRate;
    }

    /** @dev Get the current yield slash for the given token */
    function currentYieldSlash(IERC20 _token) public view returns (uint256) {
        return NumYields[_token].div(yieldSlashRate);
    }

    /** @dev Yield new tokens as a reward to the caller if approved to do so by the yield function */
    function yield(IERC20 _token) external {
        address account = _msgSender();
        (uint256 stake, uint256 borrowed) = yieldApproved.yieldApproved(account, _token);
        require(stake > 0 || borrowed > 0, "Account has not staked or borrowed this token to earn a yield on it");

        uint256 stakeReward = 0;
        if (stake > 0) {
            
        }
        _mint(account, stakeReward);

        uint256 borrowedReward = 0;
        _mint(account, borrowedReward);

        NumYields[_token] = NumYields[_token].add(1);
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