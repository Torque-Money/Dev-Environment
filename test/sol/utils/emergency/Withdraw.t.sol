//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {EmergencyBase} from "./EmergencyBase.sol";
import {UsesTokenBase} from "../../helpers/UsesTokenBase.sol";

import {Config} from "../../helpers/Config.sol";
import {MockEmergency} from "../../../mocks/MockEmergency.sol";

contract Withdraw is EmergencyBase, UsesTokenBase {
    MockEmergency private emergency;

    function setUp() public override {
        super.setUp();

        emergency = _getEmergency();
    }

    // Test that an ERC20 token is withdrawable
    function testERC20Withdraw() public useFunds {}

    // Test that ETH is withdrawable
    function testETHWithdraw() public {}

    function _getCheats() internal view virtual override(EmergencyBase, UsesTokenBase) returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
