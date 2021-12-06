//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IOracle.sol";
import "./ILPool.sol";

contract FlashLoanLender is IERC3156FlashLender, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private oracle;
    address private lPool;

    constructor(address oracle_, address lPool_) {
        oracle = oracle_;
        lPool = lPool_;
    }
    
    function maxFlashLoan(address _token) public view override returns (uint256 _max) {
        // Make sure that the token is approved
        require(ILPool(lPool).isApprovedAsset(_token), "This token is not approved");
        _max = IERC20(_token).balanceOf(lPool);
    }

    function flashFee(address _token, uint256 _amount) public view override returns (uint256 _fee) {
        // Make sure that the token is approved
        require(ILPool(lPool).isApprovedAsset(_token), "This token is not approved");

        // Calculate the fee rate
        uint256 timeframe = uint256(5).mul(IOracle(oracle).getInterestInterval()).div(100);
        _fee = IOracle(oracle).calculateInterest(_token, timeframe, _amount);
    }

    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bool) {
        // Check that the loan satisfies the requirements
        require(ILPool(lPool).isApprovedAsset(_token), "This token is not approved");
        require(_amount <= maxFlashLoan(_token), "This amount exceeds the max flash loan amount");
        uint256 fee = flashFee(_token, _amount);
        require(fee > 0, "Borrow amount is not large enough");

        // Borrow the tokens from the liquidity pool and check they have been returned
        ILPool(lPool).lend(_token, _amount, address(_receiver));
        _receiver.onFlashLoan(_msgSender(), _token, _amount, fee, _data);
        require(IERC20(_token).balanceOf(lPool) >= _amount + fee, "Failed to payback loan");

        // Perform success
        emit FlashLoan(address(_receiver), _token, _amount, _data);
        return true;
    }

    // ======== Events ========
    event FlashLoan(address indexed receiver, address indexed token, uint256 amount, bytes data);
}