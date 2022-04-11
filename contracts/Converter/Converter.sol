//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IConverter} from "./IConverter.sol";
import {ConverterConvert} from "./ConverterConvert.sol";

contract Converter is Initializable, IConverter, ConverterConvert {
    function initialize(address router_) external initializer {
        initializeConverterCore(router_);
    }

    function maxAmountTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) public view override(IConverter, ConverterConvert) returns (uint256) {
        return super.maxAmountTokenInTokenOut(tokenIn_, amountIn_, tokenOut_);
    }

    function minAmountTokenInTokenOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) public view override(IConverter, ConverterConvert) returns (uint256) {
        return super.minAmountTokenInTokenOut(tokenIn_, tokenOut_, amountOut_);
    }

    function swapMaxTokenInTokenOut(
        address tokenIn_,
        uint256 amountIn_,
        address tokenOut_
    ) public override(IConverter, ConverterConvert) returns (uint256) {
        return super.swapMaxTokenInTokenOut(tokenIn_, amountIn_, tokenOut_);
    }

    function swapMaxEthInTokenOut(address tokenOut_) public payable override(IConverter, ConverterConvert) returns (uint256) {
        return super.swapMaxEthInTokenOut(tokenOut_);
    }

    function swapMaxTokenInEthOut(address tokenIn_, uint256 amountIn_) public override(IConverter, ConverterConvert) returns (uint256) {
        return super.swapMaxTokenInEthOut(tokenIn_, amountIn_);
    }
}
