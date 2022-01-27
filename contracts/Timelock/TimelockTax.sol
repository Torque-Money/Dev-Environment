//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";

contract TimelockTax is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // **** Potentially change this to be made into the onlyOwner of the timelock itself for delayed operations ?

    address public taxAccount;
    FractionMath.Fraction private _taxPercentage;

    uint256 public immutable taxCooldown;
    uint256 public lastTax;

    constructor(
        uint256 taxPercentageNumerator_,
        uint256 taxPercentageDenominator_,
        uint256 taxCooldown_
    ) {
        taxAccount = _msgSender();

        _taxPercentage.numerator = taxPercentageNumerator_;
        _taxPercentage.denominator = taxPercentageDenominator_;

        taxCooldown = taxCooldown_;
    }

    modifier onlyTaxAccount() {
        require(_msgSender() == taxAccount, "TimelockTax: Only the tax account may call this");
        _;
    }

    // Get the tax percentage
    function taxPercentage() public view returns (uint256, uint256) {
        return (_taxPercentage.numerator, _taxPercentage.denominator);
    }

    //  Transfer the tax account
    function setTaxAccount(address account_) external onlyTaxAccount {
        taxAccount = account_;
    }

    // Claim tax for a given token
    function claimTax(address token_) external onlyTaxAccount {
        require(block.timestamp >= lastTax.add(taxCooldown), "TimelockTax: Too early to claim tax");

        uint256 bal = IERC20(token_).balanceOf(address(this));
        uint256 tax = bal.mul(_taxPercentage.numerator).div(_taxPercentage.denominator);
        IERC20(token_).safeTransfer(taxAccount, tax);

        lastTax = block.timestamp;
    }
}