# Torque Money Whitepaper

## Code

-   [Protocol repository](https://github.com/Terragonn/Torque-Protocol-V1)
-   [Frontend repository](https://github.com/Terragonn/Torque-Frontend)

## Deployed contracts

## Introduction

Torque Finance is a lending and leveraging protocol that allows our users to leverage huge amounts against their collateral without risk to the protocol itself. We believe that leveragers should be able to leverage as much as they wish without restriction, while of course understanding the risks that come with such a dangerous position.

Stakers may lock assets in the pool for a given period of time, where those assets will be lent out to leveragers. At the end of the period the leveragers take their earnings after paying interest, and the stakers receive their stake in the pool based on what they deposited.

## High level overview

### Value retention

Due to the way that the protocol works, in theory, the total value of the pool should always be increasing in value, meaning that staking is a delta neutral strategy. The pool does this in a few different ways:

1. Whenever a user opens a leveraged position, they will be accumulating interest on their initial investment. This interest is redistributed back to the pool once the debt has been repaid which goes back to the stakers.
2. Whenever a users collateral is not enough to back their position, they will be liquidated, where their collateral will be our compensation for the losses that they incurred while using our money. However while the asset borrowed against may have lost its value, the protocol still remains the exact same amount of tokens it began with, which means that the value of those assets is the same as if the staker just held onto their collateral themselves, however they will be rewarded with the additional liquidated tokens, and therefore this can be seen as profit for the pool increasing its value to what it initially was.
3. If the leveragers position increases in value, they will be compensated with the respective amount of tokens that represents their tokens increase in value. However while the pool loses tokens, the remaining tokens it holds onto represents the same initial value the pool started with, so the pool has never lost its value.

### Periods

The protocol moves in cycles of different periods. This allows the protocol to solve the "bank run" problem, where if stakers try and redeem their staked assets that have been lended out, it could spark panic which would cause the entire protocol to collapse, not to mention the inconvenience of no guarantee of when their funds will be available for withdrawal.

By working in terms of periods, where only the current period may be used for staking and borrowing, it allows users to stake their money for a fixed amount of time, and at the end be guaranteed to withdraw the full amount of their earnings whenever they want. In doing so as well it solves the rebasing issue where some stakers stake right at the end of the period and become entitled to the same rewards that the stakers who staked for the full amount of time earned using their money.

However this concept of the protocol moving in periods does have some drawbacks. One issue is that the protocol does not auto reinvest stakers money, which means if they wish to compound their money they must manually restake at the start of the next given period. However this issue is simple enough to be solved by a bot or farm which would automatically restake funds at the start of a new period.

### Staking

Stakers provide liquidity to the pool which leveragers use in their position. At the start of the period, stakers will be allowed to deposit assets into the pool, and in turn their receive a stake proportional to the amount of the given asset they deposited.

After the prologue phase and for the rest of the period, stakers will not be able to withdraw their stake. This ensures that the initial amount of liquidity remains for the leveragers to use in their positions. However they may stake into a future pool for use with a future period.

After the period has ended, the stakers may redeem their initial token investment for their share of the pools value that they are entitled to.

### Margin loans and leverage

The stakers provide liquidity for the leveragers to come and use to open up a margin position.

In order to open up a leveraged position, leveragers will have to deposit an initial amount of collateral to borrow against first. This collateral will be used to repay a loss incurred by the leverager if their investment decreases in value. Leveragers should deposit more collateral to protect your account from being liquidated in the case of a significant negative price movement.

Once the staking period has ended and given that they have some collateral in their account, leveragers will be able to borrow as much of another asset is available against their collateral. Leveragers will be required to hold their position for a minimum amount of time before they may repay their debts. This is to prevent spam to the protocol. Leveragers will also be charged interest on their initial borrow proportional to the amount of time they borrow and the ratio of the asset borrowed to the total amount of the asset locked.

If at any time during a leveraged position the margin level of the leverager falls below the minimum margin level, the account will be open up to be liquidated by another user, where the accounts collateral will be taken to pay off their debts.

At the end of the period users will be forced to repay their debt, or else someone else will be able to repay their debt while taking a percentage of their collateral. If the borrow amount fell below the initial borrow value, then some collateral will be subtracted to compensate for this, and if the borrow amount is above, then the respective amount of the collateral asset will be added to the collateral. It should be noted that repaying may be done at any time as long as the time borrowed has exceeded the minimum borrow period and will reset the accounts debt to zero.

At any point during the period or after the period, as long as the leverager has repaid their debt, they may withdraw their collateral.

### Flash liquidations

When a leveraged accounts margin level falls below the minimum level, that accounts position will be open to be flash liquidated. Flash liquidators simply call the function which automatically swaps the collateral with the specified amount of borrowed tokens to pay the pool back.

The liquidator will be allocated a percentage of the collateral to compensate them for their service and to thank them for helping the protocol to operate smoothly.

## Calculations

### Interest

Interest rates can be calculated by the formula:

-   `d` = amount of asset lended out
-   `p` = amount of asset locked in pool and liquid
-   `i` = interest rate
-   `i = d / (d + p)`

We will calculate the interest rate continuously over a given interval. This will not compound. We can know how much interest has been accumulated by the time between when the amount was borrowed and the current time. The interest can be calculated with the following formula:

-   `k` = max percent interest
-   `t_0` = initial time
-   `t_c` = current time
-   `b_0` = value of amount borrowed initially in relation to the deposited asset
-   `i` = interest rate (as seen above)
-   `I` = interest
-   `I = k * b_0 * i * (t_c - t_0)`

### Margin levels

At all times the formula must satisfy the following equation. If the equation is no longer satisfied, the user will be opened up to be liquidated:

-   `b_t` = value of borrowed amount relative to deposited asset at time t
-   `d_t` = amount of asset deposited at time t
-   `i_t` = interest accumulated at time t
-   `a` = alpha overcollateralized ratio
-   `a < (b_t + d_t) / (b_0 + i_t)`

### Repayments

The repayment value can be calculated using the following formula:

-   `d` = amount deposited
-   `b_t` = value of borrowed amount at time t relative to deposited asset
-   `i_t` = interest at time t
-   `R` = repayment value in terms of deposited asset
-   `R = d + b_t - b_0 - i_t`

When the repayment is made, if the repayment value is less than or equal to the deposit value, then the user must repay the following amount:

-   `b_t` = value of amount borrowed at time t in terms of deposited asset
-   `i_t` = interest at time t
-   `R` = repay value in terms of deposited asset
-   `R = b_0 + i_t - b_t`

If the repayment value is > deposit value, then the user will be paid out the following amount:

-   `b_t` = value of amount borrowed at time t in terms of deposited asset
-   `i_t` = interest at time t
-   `R` = repay value in terms of deposited asset
-   `R = b_t - b_0 - i_t`

## Yields

The protocol primarily earns money off of the interest it generates off of borrows. While the protocol also earns money off of liquidations, the primary purpose of the funds accumulated from these liquidations is to hedge the value of the pool against the market, and then once the market swings the opposite way this money will most likely be paid out.

Thus stakers can expect to earn a maximum yield of the current interest rate on the asset they are staking, which is proportional to the number of people staking. By redepositing, stakers compound the value of their initial investment with each period.

The true APY cannot truly be calculated as the interest rate is dynamic, however if a staker restakes their full amount throughout the whole year, the interest rate stays the same, leveragers borrow for the full amount of time, and the full amount of collateral is used by leveragers during every period, then the APY can be calculated using the following formula:

-   `s_0` = initial stake
-   `i_0` = interest rate
-   `l` = period length in days
-   `s_f` = final stake
-   `s_f = s_0 * (1 + i) ^ (365 / l)`

## DAO and governance token

WIP - a fixed number of governance tokens will be allocated back to stakers that decreases over time as an incentive to early invest in the protocol - these tokens should be worth something as to actually be an incentive

## Future plans and protocol v2

-   Allow leveragers to borrow against multiple types of assets
-   Add cross margins instead of exclusively providing isolated margins
