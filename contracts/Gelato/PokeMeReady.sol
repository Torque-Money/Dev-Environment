//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPokeMe {
    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256, address);
}

abstract contract PokeMeReady {
    IPokeMe public immutable pokeMe;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(IPokeMe _pokeMe) {
        pokeMe = _pokeMe;
        gelato = IPokeMe(_pokeMe).gelato();
    }

    modifier onlyPokeMe() {
        require(msg.sender == address(pokeMe), "PokeMeReady: onlyPokeMe");
        _;
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}
