//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../Oracle.sol";
import "../../LPool.sol";

abstract contract MarginCore is Ownable {
    using SafeERC20 for IERC20;

    Oracle public immutable oracle;
    LPool public immutable pool;

    struct BorrowAccount {
        uint256 collateral;
        uint256 borrowed;
        uint256 initialPrice;
        uint256 borrowTime;
        uint256 initialBorrowTime;
    }
    struct BorrowPeriod {
        uint256 totalBorrowed;
        mapping(address => mapping(IERC20 => BorrowAccount)) collateral; // account => token => borrow - the same account can have different borrows with different collaterals independently
        mapping(address => uint256) borrowed; // Store the total of the asset borrowed for each account
    }

    mapping(uint256 => mapping(IERC20 => BorrowPeriod)) internal BorrowPeriods;

    constructor(Oracle oracle_, LPool pool_) {
        oracle = oracle_;
        pool = pool_;
    }

    modifier onlyApproved(IERC20 _token) {
        require(pool.isApproved(_token), "This token has not been approved");
        _;
    }

    function _swap(IERC20 _token1, IERC20 _token2, uint256 _amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);

        address router = address(oracle.router());
        _token1.safeApprove(address(router), _amount);
        return UniswapV2Router02(router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp + 1 hours)[1];
    }
}