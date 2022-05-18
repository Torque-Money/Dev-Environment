//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {Base} from "../../bases/Base.sol";

import {MockSupportsToken} from "../../mocks/MockSupportsToken.sol";
import {Config} from "../../helpers/Config.sol";

abstract contract BaseSupportsToken is Base {
    MockSupportsToken internal _supportsToken;

    IERC20Upgradeable[] internal _token;

    function setUp() public virtual override {
        super.setUp();

        _token = Config.getToken();
        _supportsToken = new MockSupportsToken(_token);
    }
}
