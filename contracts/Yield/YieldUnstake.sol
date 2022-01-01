//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./YieldAccount.sol";
import "./YieldRates.sol";

abstract contract YieldStake is YieldAccount, YieldRates {
    using SafeMath for uint256;

    // Get the owed balance distributed to an account
    function owedBalance(IERC20 token_, address account_) public view returns (uint256) {
        uint256 owed = _owedBalance(token_, account_);
        uint256 yield = _yield(token_, initialStakeBlock(token_, account_), staked(token_, account_));
        return owed.add(yield);
    }
    
    // Unstake tokens
    function unstake(IERC20 token_, uint256 amount_) external {
        // **** I need to cash the users rewards into the owed balance and reset the block
        // uint256 owed = owedBalance(token_, _msgSender());
        // **** How will this owed thing work depending on how much they cash out - only perform a yield on the amount that they chose using custom yield ?
    }

    // Claim yield rewards for a given account
    function claimYield(IERC20 token_) external {
        uint256 owed = owedBalance(token_, _msgSender());
        token.mint(_msgSender(), owed);
        _setOwedBalance(token_, 0, _msgSender());
        _setInitialStakeBlock(token_, block.number, _msgSender());
    }

    event Unstake();
    event Claim();
}