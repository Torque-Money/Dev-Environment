//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/UniswapV2Router02.sol";
import "./lib/Median.sol";

contract Oracle is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Median for uint256[];

    UniswapV2Router02[] private Routers;
    mapping(UniswapV2Router02 => bool) private StoredRouters;

    uint256 public immutable decimals;

    constructor(uint256 decimals_) {
        decimals = decimals_;
    }

    // ======== Routers ========

    /** @dev Adds a new router to be used in price calculation */
    function addRouter(UniswapV2Router02 _router) external onlyOwner {
        require(StoredRouters[_router] != true, "This router has already been added");
        Routers.push(_router);
        StoredRouters[_router] = true;
    }

    /** @dev Return the list of routers used in the oracle */
    function routers() external view returns (UniswapV2Router02[] memory) { return Routers; }

    /** @dev Returns a pseudo-random router to use */
    function router() external view returns (UniswapV2Router02) {
        uint256 index = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp))).mod(Routers.length);
        return Routers[index];
    }

    // ======== Verify price from multiple sources ========

    /** @dev Returns the median price of the amount of tokens 2 from tokens 1 over the stored exchanges */
    function pairPrice(IERC20 _token1, IERC20 _token2) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);

        uint256[] memory prices = new uint256[](Routers.length);
        for (uint256 i = 0; i < Routers.length; i++) {
            prices[i] = Routers[i].getAmountsOut(decimals, path)[1];
        }
        return prices.median();
    }
}