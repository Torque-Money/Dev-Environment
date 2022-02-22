import {Contract, ethers} from "ethers";
import {ERC20} from "../../../typechain-types";

export async function setPrice(oracle: Contract, token: ERC20, rawPrice: ethers.BigNumber) {
    const priceDecimals = await oracle.priceDecimals();
    const price = ethers.BigNumber.from(10).pow(priceDecimals).mul(rawPrice);
    await (await oracle.setPrice(token.address, price)).wait();

    return price;
}
