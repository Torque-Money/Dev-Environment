//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBeefyVaultV6 {
    function want() external view returns (IERC20Upgradeable);

    function balance() external view returns (uint256);

    function available() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function depositAll() external;

    function deposit(uint256 _amount) external;

    function earn() external;

    function withdrawAll() external;

    function withdraw(uint256 _shares) external;
}
