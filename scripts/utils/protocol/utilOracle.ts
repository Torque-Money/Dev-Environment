import {Contract, ethers} from "ethers";

import {ERC20Upgradeable} from "../../../typechain-types";

// Set the price of a given token
export async function setPrice(oracle: Contract, token: ERC20Upgradeable, rawPrice: ethers.BigNumber, useDecimals: boolean = true) {
    const priceDecimals = await oracle.priceDecimals();

    let price;
    if (useDecimals) {
        price = ethers.BigNumber.from(10).pow(priceDecimals).mul(rawPrice);
    } else price = rawPrice;
    await (await oracle.setPrice(token.address, price)).wait();

    return price;
}

// Change the price of a token by a percentage
export async function changePrice(oracle: Contract, token: ERC20Upgradeable, percentChange: number) {
    const ROUND_DECIMALS = 10 ** 5;

    const currentPrice = await oracle.priceMax(token.address, ethers.BigNumber.from(10).pow(await oracle.decimals(token.address)));
    const newPrice = currentPrice.mul(Math.floor(percentChange * ROUND_DECIMALS)).div(ROUND_DECIMALS);
    await (await oracle.setPrice(token.address, newPrice)).wait();
}
