//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

abstract contract TreasurerEpoch {
    struct Epoch {
        uint256 time;
        mapping(address => uint256) remainingAmountStaked;
        mapping(address => uint256) remainingReserveTokens;
        mapping(address => uint256) totalAmountStaked;
        uint256 totalMintedReserveTokens;
    }

    mapping(uint256 => Epoch) private _epochs;
    uint256 public epochId;

    // Set the epoch time
    function _setEpochTime(uint256 time_, uint256 epochId_) internal {
        Epoch storage epoch = _epochs[epochId_];
        epoch.time = time_;
    }

    // Get the epoch time
    function epochTime(uint256 epochId_) public view returns (uint256) {
        Epoch storage epoch = _epochs[epochId_];
        return epoch.time;
    }

    // Set the total amount staked for the epoch
    function _setEpochTotalAmountStaked(
        address token_,
        uint256 amount_,
        uint256 epochId_
    ) internal {
        Epoch storage epoch = _epochs[epochId_];
        epoch.totalAmountStaked[token_] = amount_;
    }

    // Get the total amount staked for the epoch
    function epochTotalAmountStaked(address token_, uint256 epochId_) public view returns (uint256) {
        Epoch storage epoch = _epochs[epochId_];
        return epoch.totalAmountStaked[token_];
    }

    // Set the total minted reserve tokens for the epoch
    function _setEpochTotalMintedReserveTokens(uint256 amount_, uint256 epochId_) internal {
        Epoch storage epoch = _epochs[epochId_];
        epoch.totalMintedReserveTokens = amount_;
    }

    // Get the total minted reserve tokens for the epoch
    function epochTotalMintedReserveTokens(uint256 epochId_) public view returns (uint256) {
        Epoch storage epoch = _epochs[epochId_];
        return epoch.totalMintedReserveTokens;
    }

    // Set the remaining amount staked for the epoch
    function _setEpochRemainingAmountStaked(
        address token_,
        uint256 amount_,
        uint256 epochId_
    ) internal {
        Epoch storage epoch = _epochs[epochId_];
        epoch.remainingAmountStaked[token_] = amount_;
    }

    // Get the remaining amount staked for the epoch
    function _epochRemainingAmountStaked(address token_, uint256 epochId_) internal view returns (uint256) {
        Epoch storage epoch = _epochs[epochId_];
        return epoch.remainingAmountStaked[token_];
    }

    // Set the remaining reserve tokens for the epoch
    function _setEpochRemainingReserveTokens(
        address token_,
        uint256 amount_,
        uint256 epochId_
    ) internal {
        Epoch storage epoch = _epochs[epochId_];
        epoch.remainingReserveTokens[token_] = amount_;
    }

    // Get the remaining reserve tokens for the epoch
    function _epochRemainingReserveTokens(address token_, uint256 epochId_) internal view returns (uint256) {
        Epoch storage epoch = _epochs[epochId_];
        return epoch.remainingReserveTokens[token_];
    }
}
