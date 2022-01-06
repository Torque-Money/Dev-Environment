# Torque Money Whitepaper

## A DeFi leveraging protocol that allows users to leverage as much as they wish against their collateral whilst providing high (currently market neutral) returns to liquidity providers.

### Disclaimer: Please note that everything explained in this whitepaper is purely hypothetical and should not be considered as fact. This is experimental technology and nothing is certain.

### Code

All of the most up to date code can be found in the [official repository](https://github.com/Torque-Money/Torque-Protocol). In addition the code can be verified on most blockchain explorers.

### Deployed contracts

**As of the current point in time no contracts have been deployed. If you see a contract that claims to be ours that is not listed here, please verify it with us first before using it**

### Motivation

The purpose of the protocol is to provide unlimited leveraging to our users. Traditional lending platforms only allow you to leverage up to a certain amount against your collateral, however we believe that this should not be the standard, and this protocol aims to remove this cap so that the only limit is the amount of liquidity in the leveraging pool.

We also wish to provide some of the best interest rates to our liquidity providers in the market whilst providing them with a mostly market neutral return. _Please note that future changes to the protocol might make the lending strategy more or less market neutral_

### High level overview

#### Staking

Staking or liquidity providing is where a user deposits tokens into the liquidity pool. Stakers will receive tokens that represent the share of the pool that they are entitled to. These tokens may be redeemed at any time for the percentage of the underlying asset they initially deposited that they are entitled to.

Staked tokens will be lended out to leveragers who will have to pay an interest rate on what they borrow. This interest will then be distributed back to the pool, and thus the stakers, who will receive their share of interest that they are entitled to when they redeem their tokens.

Staking is essential to the protocol as with no liquidity, there is nothing for the leveragers to borrow, which would render the protocol useless.

#### Leveraging

Leveraging is where a user borrows money to invest with and is then entitled to the earnings made from the investment or is required to repay the losses incurred from the investment.

When a user enters a leveraged position, they will be required to put down some collateral which will be used to repay any losses incurred by you if your investment loses money. You may withdraw this collateral at any time, however you may not withdraw an amount that will cause your account to be undercollateralized. In addition to this you must deposit a minimum amount of collateral before being allowed to leverage.

Traditional leveraging platforms will only allow you to borrow up to 5x or 10x against the value of your collateral, however with us you may borrow as much as you wish as long as there is liquidity available. With great power comes even greater responsibility however. The more you leverage, the less the price of the investment you made needs to drop by before you get liquidated. Liquidation is where your collateral will be taken to repay losses incurred by your investment.

To demonstrate the risks of leveraging, lets say that you have 1000UST as collateral and you borrow 1BTC worth 40000UST. If that 1BTC you borrowed drops from 40000UST to 39000UST (a 2.5% price drop), you will be liquidated, which will mean your 1000UST will be taken from you to repay the losses from your investment.

Your margin level along with how at risk your account is of being liquidated will be displayed on the dashboard of our web dapp.

Please note that in addition to the price of the asset you borrowed against losing value causing you to be liquidated, other factors that can cause your account to be liquidated include:

- Accumulating too much interest
- The value of your deposited collateral dropping in value

### Core analysis

#### Staking

#### Leveraging

### Token

### DAO

### Future plans
