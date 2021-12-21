import hre from "hardhat";

export default async function timeTravel(minutes: number) {
    hre.run("time", minutes);
}
