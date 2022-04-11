# Requirements for V2 contracts

**NOTE: Keep this document in sync with all other copies of the document and vice versa.**

### Overall requirements

-   There should be a central registry for contracts
-   Contracts should be as modular as possible
-   Bot contract needs to be funded at all times
-   Methods needs to be clear, simple, and robust

### Pool requirements

-   The pool should rebalance funds into allocated strategies of its own choosing
-   Funds should be distributed over many of the best strategies for diversification and risk management
-   Funds should be highly liquid and available at any time
-   All funds must be considered for users trying to redeem their current share

### Strategy requirements

-   Strategies should be modular
-   Strategy changes should be automatically executed
-   Strategy changes need to go through a timelock before being rebalanced and should be able to be blocked
-   The method for choosing a strategy needs to be decentralized

### Account requirements

-   Hold all collateral
-   Cannot remove collateral when position is leveraged
-   Tracks the equity
-   Calculate risk level
-   Track position duration
-   Track open positions

### Price oracle requirements

-   Needs to be able to calculate the price of a given asset
-   Needs to be able to calculate the amount of an asset from the given price
-   Needs to be able to support LP tokens

### DEX requirements

-   DEX router will execute the swap on the exchange with the best rates
-   DEX provider will provide a modular interface for the protocol to plug into for modularity

### Interest requirements

-   Users must be offered a fixed interest rate that lasts for a given amount of time
-   Interest must be accrued automatically
-   Interest will have to be paid back after the given amount of time expires
-   Accounts will automatically have their losses paid out and their interest rates reset after the given time period expires

### Margin requirements

-   Needs to be robust enough to be able to deal with a liquidation
-   Needs to maintain over-collateralization in the lender at all times
-   Lenders must be able to be swapped out whilst not affecting current positions
-   Accounts that are too highly leveraged, lack collateral, or are past their expiry date must be manually derisked
-   Interest needs to be taken into consideration including the lending protocols own interest rate
-   Deleveraged positions should automatically exchange assets and close the lended position
-   The protocol must be available to absorb fees at all times
-   A separate entity will have the right to close any at risk positions
-   Closing positions needs to be robust in every situation (slippage, lack of liquidity should not affect the ability to liquidate)
-   Lending providers will have to automatically compound yields earned during the time lending and rewards such as interest
-   All leveraged positions are opened for a given amount of time and have a fixed interest rate set at the current variable rate
-   Leveraged positions may only be open for a given amount of time before they will be closed
-   When an account is closed automatically the user will be taxed some of their collateral
-   It should be easy to maintain a position compared to having to reset it via gas costs

### Lending requirements

### Additional requirements

-   Necessary protocol analytics need to be tracked
