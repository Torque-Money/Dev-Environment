interface YieldApproved {
    /**
     *  @dev Check if an account is approved to yield tokens
     */
    function yieldApproved(address _account) external returns (bool);
}