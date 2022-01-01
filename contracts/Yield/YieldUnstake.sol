//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./YieldAccount.sol";
import "./YieldRates.sol";

abstract contract YieldUnstake is YieldAccount, YieldRates {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Get the owed balance distributed to an account
    function owedBalance(IERC20 token_, address account_) public view returns (uint256) {
        uint256 owed = _owedBalance(token_, account_);
        uint256 yield = _yield(token_, initialStakeBlock(token_, account_), staked(token_, account_));
        return owed.add(yield);
    }
    
    // Unstake tokens
    function unstake(IERC20 token_, uint256 amount_) external {
        uint256 currentStaked = staked(token_, _msgSender());
        require(amount_ <= currentStaked, "Cannot unstake more than amount staked");

        token_.safeTransfer(_msgSender(), amount_);

        _setOwedBalance(token_, owedBalance(token_, _msgSender()), _msgSender());
        _setInitialStakeBlock(token_, block.number, _msgSender());
        _setStaked(token_, currentStaked.sub(amount_), _msgSender());
        emit Unstake(_msgSender(), token_, amount_);
    }

    // Claim yield rewards for a given account
    function claimYield(IERC20 token_) external {
        uint256 owed = owedBalance(token_, _msgSender());
        token.mint(_msgSender(), owed);

        _setOwedBalance(token_, 0, _msgSender());
        _setInitialStakeBlock(token_, block.number, _msgSender());
        emit ClaimYield(_msgSender(), token_, owed);
    }

    event Unstake(address indexed account, IERC20 token, uint256 amount);
    event ClaimYield(address indexed account, IERC20 token, uint256 amount);
}