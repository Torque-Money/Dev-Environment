//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Converter/IConverter.sol";
import "../Oracle/IOracle.sol";

abstract contract LPoolCore is Initializable, AccessControl {
    bytes32 public constant POOL_ADMIN = keccak256("POOL_ADMIN_ROLE");
    bytes32 public constant POOL_APPROVED = keccak256("POOL_APPROVED_ROLE");

    IConverter public converter;
    IOracle public oracle;

    function initialize(IConverter converter_, IOracle oracle_) external initializer {
        _setRoleAdmin(POOL_ADMIN, POOL_ADMIN);
        _setRoleAdmin(POOL_APPROVED, POOL_ADMIN);
        _grantRole(POOL_ADMIN, _msgSender());

        converter = converter_;
        oracle = oracle_;
    }

    // Set the converter to use
    function setConverter(IConverter converter_) external onlyRole(POOL_ADMIN) {
        converter = converter_;
    }

    // Set the oracle to use
    function setOracle(IOracle oracle_) external onlyRole(POOL_ADMIN) {
        oracle = oracle_;
    }
}
