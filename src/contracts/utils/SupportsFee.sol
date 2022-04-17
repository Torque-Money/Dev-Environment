//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {ISupportsFee} from "../interfaces/utils/ISupportsFee.sol";

abstract contract SupportsFee is Initializable, AccessControlUpgradeable, ISupportsFee {
    bytes32 public FEE_ADMIN_ROLE;

    address private recipient;

    function __SupportsFee_init(address _recipient) internal onlyInitializing {
        __SupportsFee_init_unchained(_recipient);
    }

    function __SupportsFee_init_unchained(address _recipient) internal onlyInitializing {
        FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
        _setRoleAdmin(FEE_ADMIN_ROLE, FEE_ADMIN_ROLE);
        _grantRole(FEE_ADMIN_ROLE, _msgSender());

        recipient = _recipient;
    }

    // Set the fee recipient.
    function setFeeRecipient(address _recipient) external virtual override onlyRole(FEE_ADMIN_ROLE) {
        recipient = _recipient;
    }

    // Get the fee recipient.
    function feeRecipient() public view virtual override returns (address _recipient) {
        return recipient;
    }
}
