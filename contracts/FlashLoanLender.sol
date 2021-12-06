//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IOracle.sol";

contract FlashLoanLender is IERC3156FlashLender, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private calculator;
    address private lPool;

    constructor(address calculator_, address lPool_) {
        calculator = calculator_;
        lPool = lPool_;
    }
    
    function maxFlashLoan(address _token) public view override returns (uint256) {
        
    }

    function flashFee(address _token, uint256 _amount) public view override returns (uint256) {

    }

    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bool) {

    }

    // ======== Setters ========
}