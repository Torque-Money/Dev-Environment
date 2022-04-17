//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {ISupportsFee} from "../interfaces/utils/ISupportsFee.sol";

abstract contract SupportsFee is Initializable, AccessControlUpgradeable, ISupportsFee {
    bytes32 public FEE_ADMIN_ROLE;

    address private recipient;
    uint256 private _feePercent;
    uint256 private _feeAmount;

    function __SupportsFee_init(
        address _recipient,
        uint256 feePercent_,
        uint256 feeAmount_
    ) internal onlyInitializing {
        __SupportsFee_init_unchained(_recipient, feePercent_, feeAmount_);
    }

    function __SupportsFee_init_unchained(
        address _recipient,
        uint256 feePercent_,
        uint256 feeAmount_
    ) internal onlyInitializing {
        FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
        _setRoleAdmin(FEE_ADMIN_ROLE, FEE_ADMIN_ROLE);
        _grantRole(FEE_ADMIN_ROLE, _msgSender());

        recipient = _recipient;
        _feePercent = feePercent_;
        _feeAmount = feeAmount_;
    }

    function setFeePercent(uint256 feePercent_) external onlyRole(FEE_ADMIN_ROLE) {
        _feePercent = feePercent_;
    }

    function feePercent() public view virtual override returns (uint256 percent) {
        return _feePercent;
    }

    function setFeeAmount(uint256 feeAmount_) external onlyRole(FEE_ADMIN_ROLE) {
        _feeAmount = feeAmount_;
    }

    function feeAmount() public view virtual override returns (uint256 percent) {
        return _feeAmount;
    }

    function setFeeRecipient(address _recipient) external virtual override onlyRole(FEE_ADMIN_ROLE) {
        recipient = _recipient;
    }

    function feeRecipient() public view virtual override returns (address _recipient) {
        return recipient;
    }
}
