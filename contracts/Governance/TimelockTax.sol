//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/FractionMath.sol";

contract TimelockTax is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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

    modifier onlyTax() {
        require(_msgSender() == taxAccount, "Only the tax account may call this");
        _;
    }

    // Get the tax percentage
    function taxPercentage() external view returns (uint256, uint256) {
        return (_taxPercentage.numerator, _taxPercentage.denominator);
    }

    //  Transfer the tax account
    function setTaxAccount(address _account) external onlyTax {
        taxAccount = _account;
    }

    // @dev Claim tax for a given token
    function claimTax(IERC20 _token) external onlyTax {
        require(block.timestamp >= lastTax.add(taxCooldown));

        uint256 bal = _token.balanceOf(address(this));
        uint256 tax = bal.mul(_taxPercentage.numerator).div(_taxPercentage.denominator);
        _token.safeTransfer(taxAccount, tax);

        lastTax = block.timestamp;
    }
}
