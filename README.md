# Torque Money Whitepaper

## A DeFi leveraging protocol that allows users to leverage as much as they wish against their collateral whilst providing high (currently market neutral) returns to liquidity providers.

### Disclaimer: Please note that everything explained in this whitepaper is purely hypothetical and should not be considered as fact. This is experimental technology and nothing is certain.

### Official links

**Currently we do not have any official links**

### Code

All of the most up to date code can be found in the [official repository](https://github.com/Torque-Money/Torque-Protocol). In addition the deployed smart contract code can be verified on most blockchain explorers.

### Deployed contracts

**As of the current point in time no contracts have been deployed. If you see a contract that claims to be ours that is not listed here, please verify it with us first before using it**

### Motivation

Our aim is to provide unlimited leveraging to everyone. Traditional lending platforms typically cap the amount you may borrow, for example 5x or 10x against your collateral. However, we believe that this should not be the case, and our protocol aims to remove this cap so that the only limit is the amount of liquidity in the leveraging pool.

We also wish to provide some of the best interest rates to our liquidity providers in the market.

### High level overview

#### Staking

Staking or liquidity providing is where a user deposits tokens into our liquidity pool. In exchange, stakers will receive tokens that represent their share of the pool. These tokens may be redeemed at any time for the percentage of the underlying asset they initially deposited that they are entitled to, given that there is liquidity available.

Staked tokens will be lended out to leveragers who will have to pay an interest rate on what they borrow. This interest will then be distributed back to the pool, and thus the stakers, who will receive their share of interest that they are entitled to when they redeem their tokens for their underlying assets.

Staking is essential to the protocol as with no liquidity, there would be nothing for the leveragers to borrow, which would render the protocol useless.

#### Leveraging (long only currently)

Leveraging is where a user borrows money to invest with and is then entitled to the earnings made from the investment or is required to repay the losses incurred from the investment.

When a user enters a leveraged position, they will be required to put down some collateral which will be used to repay any losses incurred by them if their investment decreases in value. Users may withdraw their collateral at any time, however they may not withdraw an amount that will cause their account to be undercollateralized or below the minimum borrow amount. In addition to this users must deposit a minimum amount of collateral before being allowed to leverage.

Traditional leveraging platforms will only allow you to borrow up to 5x or 10x against the value of your collateral, however our platform will let a user borrow as much as they wish as long as the liquidity is available. The greater the leverage, the less the price of the investment needs to decrease in value by before the account is liquidated.

Liquidation is where an accounts collateral will be taken to repay losses incurred by the accounts investment.

To demonstrate the risks of leveraging, lets say that an account has 1000UST as collateral and they borrow 1BTC worth 40000UST. If that 1BTC borrowed drops from 40000UST to 39000UST (a 2.5% price drop), the account will be liquidated, which will mean the 1000UST will be taken from the account to repay the losses from the investment.

Your margin level along with how at risk your account is of being liquidated will be displayed on the dashboard of our web dapp.

In addition to the price of the asset borrowed losing value causing an account to be liquidated, other factors that can cause liquidations include:

- Accumulating too much interest
- Having the accounts collateral decreasing in value so that it is not enough to back the incurred losses

### Advanced overview

#### Staking

When a user stakes tokens in our liquidity pool, they will receive LP tokens equal to `D * TLP / TVL` where `D` is the amount of the tokens deposited, `TLP` is the total number of LP tokens in circulation, and `TVL` is the total amount of the staked asset in the pool. LP tokens may be traded around, allowing the staker to exchange the value of their underlying assets without having to redeem them.

These staked tokens will be lended out to leveragers who will be charged an interest rate on top of what they borrow which will be redistributed back to the staker. LP tokens may be redeemed for `R * TVL / TLP` of the initial tokens staked where `R` is the amount of LP tokens to be redeemed, and `TLP` and `TVL` have the same meanings as above.

It should be noted that since staked assets are lended out, there is no guarantee that those assets will be available to be redeemed at any given moment in time. However the protocol aims to offset this by drastically boosting the interest rates whenever the utilization rate increases above a given threshold, which aims to decentivize leveraging and therefore returns liquidity to the pool.

At the current time (potential to be changed in the future), staking in the pool theoretically protects staked assets against market fluctuations, allowing staking to be considered as a market neutral strategy. When we lend assets out to leveragers, if the price of those assets increases, we pay out the amount that they went up by to the leverager while keeping the initial value of the asset, and if the price decreases, the leveragers collateral will cover the loss by a liquidation. This means that in theory, the value of those staked assets would stay the same as the initial value they were deposited at plus the interest rate accumulated.

However, this is dependent on a couple of factors. In order to be completely market neutral it would require that 100% of liquidity is used at all times which we have already proved above is virtually impossible by the interest rates. In addition to this, in the event of a big market crash, it is expected that there will be very few investors going long, further lowering the utilization rate and thus market protection. Therefore while the protocol in practice does not offer pure market neutral returns, it does provide some protection against market fluctuations, and opens the account up to being able to receive some market returns on top of an interest rate.

#### Leveraging (long only currently)

Users may leverage up to as much as they wish against their collateral, however they will need to deposit a minimum amount first. This collateral will be used to ensure that the protocol is paid back for any losses a leveraged position may incur. The minimum collateral amount is enforced so that there is always an incentive for liquidating a user, otherwise undercollateralized accounts would horde borrowed liquidity whilst being undercollateralized.

The protocol works uses a cross margin, which means different borrow positions all contribute to the accounts margin level. This means that different margin borrows can offset each other which provides the leverager with the ability to hedge huge leveraged positions even if they would traditionally lack the collateral to do so. This also means that in the case of a liquidation where one or more positions decreases in value so much that it cannot be offset by the accounts collateral or other positions, the entire account will be liquidated. A potential work around to isolate losses is to use unique crypto addresses for each asset borrowed.

While leveraging, a user will accumulate interest that compounds on a per block basis. Interest is measured from the start of the block that was initially used to make the borrow a particular asset. Repaying the asset and reborrowing it again resets the accumulated interest. The interest is charged on the initial borrow price of all of the borrows for that particular asset. Topping an account up with more collateral is a good way to pay off interest, however it is recommended that after accumulating enough interest, the account should repay and then reborrow.

Interest rates are determined by the utilization rate as well as a given max interest rate set by the owners of the protocol. As such they fluctuate over time, this is why it is recommended that after accumulating a large amount of interest, the borrowed position should be repaid, otherwise a slight interest rate movement could cause the entire account to be liquidated. In addition to this and to prevent low liquidity for stakers trying to redeem, when the utilization rate exceeds a certain threshold, interest rates will increase at a much sharper rate.

Liquidations occur when an accounts margin level falls below the safe threshold set by the owners of the protocol. In the case of a liquidation, all of the accounts collateral will be used to pay off losses incurred by the account. In addition the user who calls the liquidation function will receive a percentage of the collateral they liquidate.

At all times in order to avoid being liquidated the account must satisfy the equation `(B(0) + I(t)) * (M_min_n) < (B(t) + C(t)) * (M_min_d)` where `B(t)` is the total price of the borrowed assets at the current time `t`, `C(t)` is the total price of the collateral at current time `t`, `I(t)` is the accumulated interest at time `t`, and `M_min` is the minimum margin level seperated into `M_min_n` and `M_min_d` which represents the numerator and denominator of the min margin level respectively.

It should be noted that during the process of either repayments or liquidations, the caller will have to use a swap function. This function supports custom callbacks, where as long as the callback returns the minimum amount of the desired assets, it will be allowed. By default we provide a swap function which will take the assets, swap them at a DEX, and will then return the assets back to the caller as well as providing the address provided as extra data with any extra input tokens.

### TAU token

The TAU token will be the official governance token for the Torque ecosystem. It will be used to vote on changes to be made to the protocol through the governance and timelock contracts.

Users will be able to earn TAU by providing liquidity to the pool. As the size of the pool grows overtime, the yield rate of the token will be reduced, however as new assets are added to the pool there is a chance yield rewards will come back as an incentive to provide liquidity for new assets.

A percentage of all of the profits earned by the protocol will be used to back the price of the TAU token. At any point in time, holders of TAO may burn their TAU tokens in exchange for any of the underlying reserve assets supported by the protocol. With this we aim to ensure a rising price floor that TAU cannot fall below. In the event that the market value of TAU drops below its floor price, arbitragers will buy TAU for cheap and market price and sell it back to the treasury, which will reduce the circulating number of tokens as well as increasing buying pressure which should return the token back above its price floor. While in theory being impossible, even if the price of the token goes to zero, TAU holders will still be able to redeem their tokens for what they are worth from the reserve directly.

### DAO

The DAO will consist of the TAU token, governance contracts, and timelock contracts. All of the smart contracts deployed will be fully managed by the DAO, and changes will be voted on by holders of the TAU token.

A percentage of the profits earned by the protocol will be forwarded off to the DAO to manage. The majority of these funds will be locked away in the protocols to ensure liquidity. The remaining funds will be used to fund new projects as venture capital investments, and will be occasionally distributed out to owners of TAU.

Finally, a percentage of the DAO's treasury will be able to be withdrawn by a tax account which cannot be controlled by the DAO itself. However the tax account will only be able to withdraw a fixed percentage every fixed number of days to prevent the tax account "rugging" the treasury.

### Future plans

Our next plan is to add a shorting option to the protocol. Adding this will balance out the returns to stakers, and will encourage borrowing in both bull and bear markets which will help to bring the protocol close to its peak theoretical performing state.

In addition to this we plan to provide flashloans using our liquidity pool in which users will be able to borrow huge amounts of collateral as long as they can repay it as well as a fee back to the protocol within the same transaction. Flash loans will help boost the returns for the liquidity providers at no loss for the protocol itself.
