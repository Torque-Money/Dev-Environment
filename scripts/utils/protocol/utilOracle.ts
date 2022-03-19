import {ethers} from "ethers";

import {ERC20Upgradeable, OracleTest} from "../../../typechain-types";

import {ROUND_CONSTANT} from "../config/utilConstants";

// Set the price of a given token
export async function setPrice(oracle: OracleTest, tokens: ERC20Upgradeable[], rawPrices: ethers.BigNumber[], useDecimals: boolean = true) {
    const priceDecimals = await oracle.priceDecimals();

    let price;
    for (let i = 0; i < tokens.length; i++) {
        price = rawPrices[i];
        if (useDecimals) price = ethers.BigNumber.from(10).pow(priceDecimals).mul(price);

        await (await oracle.setPrice(tokens[i].address, price)).wait();
    }

    return price;
}

// Change the price of a token by a factor
export async function setPriceByFactor(oracle: OracleTest, tokens: ERC20Upgradeable[], changeFactors: number[]) {
    const newPrices = [];

    for (let i = 0; i < tokens.length; i++) {
        const currentPrice = await oracle.priceMax(tokens[i].address, ethers.BigNumber.from(10).pow(await oracle.decimals(tokens[i].address)));
        const newPrice = currentPrice.mul(Math.floor(changeFactors[i] * ROUND_CONSTANT)).div(ROUND_CONSTANT);

        newPrices.push(newPrice);
    }

    await setPrice(oracle, tokens, newPrices, false);
}
