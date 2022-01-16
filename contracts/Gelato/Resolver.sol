//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../MarginLong/MarginLong.sol";

contract Resolver {
    MarginLong public node;

    constructor(MarginLong node_) {
        node = node_;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        address[] memory accounts = node.getBorrowingAccounts();

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            if (node.liquidatable(account)) {
                canExec = true;
                execPayload = abi.encodeWithSelector(MarginLongLiquidate.liquidateAccount.selector, account);

                return (canExec, execPayload);
            } else if (node.resettable(account)) {
                canExec = true;
                execPayload = abi.encodeWithSelector(MarginLongRepay.resetAccount.selector, account);

                return (canExec, execPayload);
            }
        }

        return (false, bytes(""));
    }
}
