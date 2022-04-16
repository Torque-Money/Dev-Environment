//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

// Allows a contract to support a fee model to be paid to a recipient.
interface ISupportsFee {
    // Get the fee percentage.
    function feePercent() external view returns (uint256 amount);

    // Get the fee amount.
    function feeAmount() external view returns (uint256 amount);

    // Set the fee recipient.
    function setFeeRecipient(address recipient) external;

    // Get the fee recipient.
    function feeRecipient() external view returns (address recipient);
}
