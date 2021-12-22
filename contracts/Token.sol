//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IYield.sol";

contract Token is ERC20, ERC20Permit, ERC20Votes, Ownable {
    IYield public yield;

    constructor(uint256 initialSupply_, IYield yield_) ERC20("Wabbit", "WBT") ERC20Permit("WBT") {
        yield = yield_;
        _mint(owner(), initialSupply_);
    }

    /** @dev Set the yield approval function */
    function setYield(IYield _yield) external onlyOwner {
        yield = _yield;
    }

    /** @dev Yield new tokens as a reward to the yielder */
    function claimYield() external {
        address account = _msgSender();
        uint256 _yield = yield.yield(account);
        _mint(account, _yield);
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