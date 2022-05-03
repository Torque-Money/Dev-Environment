//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ICheatCodes} from "../../helpers/ICheatCodes.sol";

import {EmergencyBase} from "./EmergencyBase.sol";

import {Config} from "../../helpers/Config.sol";
import {MockEmergency} from "../../../mocks/MockEmergency.sol";

contract Withdraw is EmergencyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    MockEmergency private emergency;

    function setUp() public override {
        super.setUp();

        emergency = _getEmergency();
    }

    // Test that an ERC20 token is withdrawable
    function testERC20Withdraw() public useFunds {
        IERC20Upgradeable[] memory token = Config.getToken();
        uint256[] memory tokenAmount = Config.getTokenAmount();

        for (uint256 i = 0; i < token.length; i++) {
            token[i].safeTransfer(address(emergency), tokenAmount[i]);
            emergency.inCaseTokensGetStuck(token[i], tokenAmount[i]);

            assertEq(token[i].balanceOf(address(this)), tokenAmount[i]);
        }
    }

    function _getCheats() internal view virtual override returns (ICheatCodes _cheats) {
        return super._getCheats();
    }
}
