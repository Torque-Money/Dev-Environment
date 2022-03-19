import fs from "fs";

import mainConfig from "../../../config/config.main.json";
import testConfig from "../../../config/config.test.json";
import forkConfig from "../../../config/config.fork.json";

export type ConfigType = "main" | "test" | "fork";

export interface Approved {
    name: string;
    symbol: string;
    icon: string;
    address: string;
    decimals: string;
    setup?: {
        priceFeed: string;
        oracle: boolean;
        marginLongCollateral: boolean;
        marginLongBorrow: boolean;
        leveragePool: boolean;
        flashLender: boolean;
        maxInterestMinNumerator: string;
        maxInterestMinDenominator: string;
        maxInterestMaxNumerator: string;
        maxInterestMaxDenominator: string;
        maxUtilizationNumerator: string;
        maxUtilizationDenominator: string;
    };
}

export interface Config {
    setup: {
        converter: {
            routerAddress: string;
        };
        oracle: {
            priceDecimals: string;
            thresholdNumerator: string;
            thresholdDenominator: string;
        };
        pool: {
            taxPercentNumerator: string;
            taxPercentDenominator: string;
            timePerInterestApplication: string;
        };
        lpToken: {
            LPPrefixName: string;
            LPPrefixSymbol: string;
        };
        marginLong: {
            minCollateralPrice: string;
            maxLeverageNumerator: string;
            maxLeverageDenominator: string;
            liquidationFeePercentNumerator: string;
            liquidationFeePercentDenominator: string;
        };
        resolver: {
            taskTreasury: string;
            depositReceiver: string;
            ethAddress: string;
        };
        flashLender: {
            feePercentNumerator: string;
            feePercentDenominator: string;
        };
        timelock: {
            minDelay: string;
            proposers: string[];
        };
    };
    contracts: {
        leveragePoolAddress: string;
        oracleAddress: string;
        converterAddress: string;
        marginLongAddress: string;
        resolverAddress: string;
        timelockAddress: string;
        flashLender: string;
        flashBorrowerTest: string;
        multisig?: string;
    };
    tokens: {
        nativeCoin: Approved;
        wrappedCoin: Approved;
        lpTokens: {
            beaconAddress: string; // **** Perhaps make this have its corresponding token so that order does not matter as much ?
            tokens: string[];
        };
        approved: Approved[];
    };
}

// Select a config based on the type
export function chooseConfig(configType: ConfigType): Config {
    let config;
    if (configType === "main") config = mainConfig;
    else if (configType === "test") config = testConfig;
    else config = forkConfig;

    return config;
}

// Save the config to the specified type
export function saveConfig(config: Config, configType: ConfigType) {
    let configName;
    if (configType === "main") configName = "config.main.json";
    else if (configType === "test") configName = "config.test.json";
    else configName = "config.fork.json";
    fs.writeFileSync(configName, JSON.stringify(config));
}
