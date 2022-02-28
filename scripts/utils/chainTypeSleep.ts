import {ConfigType} from "./utilConfig";

export const SLEEP_SECONDS = 8;

export async function chainSleep(configType: ConfigType, seconds: number) {
    if (configType === "main") await new Promise<void>((res) => setTimeout(res, seconds * 1000));
}
