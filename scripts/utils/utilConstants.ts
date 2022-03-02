import {BigNumber} from "ethers";
import {ConfigType} from "./utilConfig";

export const BIG_NUM = BigNumber.from(2).pow(96);

export const COLLATERAL_PRICE = BigNumber.from(1);
export const BORROW_PRICE = BigNumber.from(100);

export const OVERRIDE_CONFIG_TYPE: ConfigType | null = null;
