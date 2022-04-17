//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {ISupportsFee} from "../interfaces/utils/ISupportsFee.sol";

contract SupportsFee is Initializable, AccessControlUpgradeable, ISupportsFee {
    bytes32 public FEE_ADMIN_ROLE;

    address private recipient;
    uint256 private percent;
    uint256 private denominator;
    uint256 private amount;

    function __SupportsFee_init(
        address _recipient,
        uint256 _percent,
        uint256 _denominator,
        uint256 _amount
    ) internal onlyInitializing {
        __SupportsFee_init_unchained(_recipient, _percent, _denominator, _amount);
    }

    function __SupportsFee_init_unchained(
        address _recipient,
        uint256 _percent,
        uint256 _denominator,
        uint256 _amount
    ) internal onlyInitializing {
        FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
        _setRoleAdmin(FEE_ADMIN_ROLE, FEE_ADMIN_ROLE);
        _grantRole(FEE_ADMIN_ROLE, _msgSender());

        recipient = _recipient;
        percent = _percent;
        denominator = _denominator;
        amount = _amount;
    }

    function setFeePercent(uint256 _percent, uint256 _denominator) external virtual onlyRole(FEE_ADMIN_ROLE) {
        percent = _percent;
        denominator = _denominator;
    }

    function feePercent() public view virtual override returns (uint256 _percent, uint256 _denominator) {
        return (percent, denominator);
    }

    function setFeeAmount(uint256 _amount) external virtual onlyRole(FEE_ADMIN_ROLE) {
        amount = _amount;
    }

    function feeAmount() public view virtual override returns (uint256 _amount) {
        return amount;
    }

    function setFeeRecipient(address _recipient) external virtual override onlyRole(FEE_ADMIN_ROLE) {
        recipient = _recipient;
    }

    function feeRecipient() public view virtual override returns (address _recipient) {
        return recipient;
    }
}
