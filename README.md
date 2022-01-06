# Torque Money Whitepaper

## A DeFi leveraging protocol that allows users to leverage as much as they wish against their collateral whilst providing high (currently market neutral) returns to liquidity providers.

### Disclaimer: Please note that everything explained in this whitepaper is purely hypothetical and should not be considered as fact. This is experimental technology and nothing is certain.

### Official links

**Currently we do not have any official links**

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

#### Leveraging (long only currently)

Leveraging is where a user borrows money to invest with and is then entitled to the earnings made from the investment or is required to repay the losses incurred from the investment.

When a user enters a leveraged position, they will be required to put down some collateral which will be used to repay any losses incurred by you if your investment loses money. You may withdraw this collateral at any time, however you may not withdraw an amount that will cause your account to be undercollateralized. In addition to this you must deposit a minimum amount of collateral before being allowed to leverage.

Traditional leveraging platforms will only allow you to borrow up to 5x or 10x against the value of your collateral, however with us you may borrow as much as you wish as long as there is liquidity available. With great power comes even greater responsibility however. The more you leverage, the less the price of the investment you made needs to drop by before you get liquidated. Liquidation is where your collateral will be taken to repay losses incurred by your investment.

To demonstrate the risks of leveraging, lets say that you have 1000UST as collateral and you borrow 1BTC worth 40000UST. If that 1BTC you borrowed drops from 40000UST to 39000UST (a 2.5% price drop), you will be liquidated, which will mean your 1000UST will be taken from you to repay the losses from your investment.

Your margin level along with how at risk your account is of being liquidated will be displayed on the dashboard of our web dapp.

Please note that in addition to the price of the asset you borrowed against losing value causing you to be liquidated, other factors that can cause your account to be liquidated include:

- Accumulating too much interest
- The value of your deposited collateral dropping in value

### Advanced overview

#### Staking

When you stake tokens in the pool, you will receive LP tokens equal to `D * TLP / TVL` where `D` is the amount of the token you deposit, `TLP` is the total number of LP tokens in circulation, and `TVL` is the total amount of the staked asset in the pool.

These staked tokens will be lended out to leveragers who will be charged an interest rate on top of what they borrow which will be redistributed back to you. When you redeem your LP tokens you will receive `R * TVL / TLP` of the initial tokens you staked where `R` is the amount of LP tokens to be redeemed, and `TLP` and `TVL` have the same meanings as above.

It should be noted that since your assets are lended out, there is no guarantee that your assets will be available to be redeemed when you wish. However the protocom aims to offset this by drastically boosting the interest rates whenever the utilization rate increases above a given threshold, which aims to drastically reduce the amount of borrowers and therefore returns liquidity to the pool.

At the current time (potential to be changed in the future), staking in the pool theoretically protects your assets against market fluctuations, allowing staking to be considered as a market neutral strategy. When we lend your assets out to leveragers, if the price of your assets increases we pay out the amount that they went up by to the leverager, and if the price of your decreases, the leveragers collateral will cover your loss. This would mean in theory that the value of your assets would stay the same as the initial value you deposited plus the interest rate accumulated, however this is dependent on a couple of factors. In order to be completely market neutral it would require that 100% of liquidity is used at all times which we have already proved above is virtually impossible, and in addition to this in the event of a big market crash it is expected that there will be very few investors going long on your assets, further lowering your market protection. Therefore while the protocol in practice does not offer pure market neutral returns, it does provide some protection against market fluctuations, and opens you up to being able to receive the increasing value of your assets.

#### Leveraging (long only currently)

Users may leverage up to as much as they wish against their collateral, however they will need to deposit a minimum amount first. This collateral will be used to ensure that the protocol is paid back for any losses your leveraged position may incur. This minimum collateral amount is enforced so that there is always an incentive for liquidating a user, otherwise undercollateralized accounts would horde borrowed liquidity whilst being undercollateralized.

The protocol works uses a cross margin, which means different amounts of borrowed assets affect the accounts overall margin level. However this also means that different margin borrows can offset each other which provides the leverager with the ability to hedge huge leveraged positions even if they would traditionally lack the collateral to do so. Additionally this means that in the case of a liquidation, your entire account will be liquidated. However a potential work around to isolate your losses is to use unique crypto addresses for each asset you wish to borrow.

While leveraging a user will accumulate interest that compounds on a per block basis. Interest is measured from the start of the block that was initially used to make the borrow a particular asset. Repaying the asset and reborrowing it again resets the accumulated interest. The interest is charged on the initial borrow price of the asset. Topping your account up with more collateral is a good way to pay off interest, however it is recommended that after accumulating enough interest you repay the assets and reborrow. This will make more sense with the next part.

Interest rates are determined by the utilization rate as well as a given max interest rate set by the owners of the protocol. As such they fluctuate over time and this is why it is recommended that after accumulating a large amount of interest you repay your loan, otherwise a slight interest rate movement could cause your entire account to be liquidated. In addition to this and to prevent low liquidity for stakers trying to redeem, when the utilization rate exceeds a certain threshold, interest rates will increase at a much sharper rate.

Liquidations occur when an accounts margin level falls below the safe threshold set by the owners of the protocol. In the case of a liquidation, all of the accounts collateral will be used to pay off losses incurred by the account. In addition the user who calls the liquidation function will receive a percentage of the collateral they liquidate.

At all times in order to avoid being liquidated the account must satisfy the equation `(B(0) + I(t)) * (M_min_n) < (B(t) + C(t)) * (M_min_d)` where `B(t)` is the total price of the borrowed assets at the current time `t`, `C(t)` is the total price of the collateral at current time `t`, `I(t)` is the accumulated interest at time `t`, and `M_min` is the minimum margin level seperated into `M_min_n` and `M_min_d` which represents the numerator and denominator of the min margin level respectively.

It should be noted that during the process of either repayments or liquidations you will have to use a swap function which supports callbacks to your own custom swap callback. This callback will receive the funds and will expect at the very minimum the amounts of the assets it specifies in the function params. By default we provide a swap function which will take the assets, swap them at the market, and will then return the assets back to the caller as well as providing the address provided as extra data with any extra input tokens.

### TAU token

The TAU token will be the official governance token for the Torque ecosystem. It will be used to vote on changes to be made to the protocol through the governance and timelock contracts.

Users will be able to earn TAU through providing liquidity to the pool. As the size of the pool grows overtime, the yield rate of the token will be reduced, however as new assets are added to the pool there is a chance yield rewards will come back as an incentive to provide liquidity for new assets.

### DAO

The DAO will consist of the TAU token, governance contracts, and timelock contracts. All of the smart contracts deployed will be fully managed by the DAO, and changes will be voted on by holders of the TAU token.

A percentage of the profits earned by the protocol will be forwarded off to the DAO to manage. The majority of these funds will be locked away in the protocols to ensure liquidity. The remaining funds will be used to fund new projects as venture capital investments, and will be occasionally distributed out to owners of TAU.

### Future plans

Our next plan is to add a shorting option to the protocol. Adding this will balance out the returns to stakers, and will encourage borrowing in both bull and bear markets which will help to bring the protocol close to its peak theoretical performing state.

In addition to this we plan to provide flashloans using our liquidity pool in which users will be able to borrow huge amounts of collateral as long as they can repay it as well as a fee back to the protocol within the same transaction. Flash loans will help boost the returns for the liquidity providers at no loss for the protocol itself.
