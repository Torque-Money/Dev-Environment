//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldCore is Ownable {
    ERC20Votes public token;
    LPool public pool;

    constructor(ERC20Votes token_, LPool pool_) {
        token = token_;
        pool = pool_;
    }

    // Set the yield distribution token
    function setToken(ERC20Votes token_) external onlyOwner {
        token = token_;
    }

    // Set the pool to use
    function setPool(LPool pool_) external onlyOwner {
        pool = pool_;
    }
}