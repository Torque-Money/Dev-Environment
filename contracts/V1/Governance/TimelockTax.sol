//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TimelockTax is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public taxAccount;
    uint256 public immutable taxPercentage;

    uint256 public immutable taxCooldown;
    uint256 public lastTax;

    constructor(uint256 taxPercentage_, uint256 taxCooldown_) {
        taxAccount = _msgSender();
        taxPercentage = taxPercentage_;
        taxCooldown = taxCooldown_;
    }

    modifier onlyTax {
        require(_msgSender() == taxAccount, "Only the tax account may call this");
        _;
    }

    /** @dev Transfer the tax account */
    function setTaxAccount(address _account) external onlyTax {
        taxAccount = _account;
    }

    /** @dev Claim tax for a given token */
    function claimTax(IERC20 _token) external onlyTax {
        require(block.timestamp >= lastTax.add(taxCooldown));

        uint256 bal = _token.balanceOf(address(this));
        uint256 tax = bal.mul(taxPercentage).div(100);
        _token.safeTransfer(taxAccount, tax);

        lastTax = block.timestamp;
    }
}