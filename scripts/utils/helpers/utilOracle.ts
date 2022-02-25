import {Contract, ethers} from "ethers";

import {ERC20} from "../../../typechain-types";

export async function setPrice(oracle: Contract, token: ERC20, rawPrice: ethers.BigNumber, useDecimals: boolean = true) {
    const priceDecimals = await oracle.priceDecimals();

    let price;
    if (useDecimals) {
        price = ethers.BigNumber.from(10).pow(priceDecimals).mul(rawPrice);
    } else price = rawPrice;
    await (await oracle.setPrice(token.address, price)).wait();

    return price;
}

export async function changePrice(oracle: Contract, token: ERC20, percentChange: number) {
    const ROUND_DECIMALS = 10 ** 5;

    const currentPrice = await oracle.priceMax(token.address, await oracle.decimals(token.address));
    const newPrice = currentPrice.mul(Math.floor(percentChange * ROUND_DECIMALS)).div(ROUND_DECIMALS);
    await (await oracle.setPrice(token.address, newPrice)).wait();
}
