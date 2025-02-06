# 🎯 Dutch Auction for Ad Slots

> Going once... going twice... going DOWN! 📉

## 🎬 Main Flow

1. 🏁 Operator starts auction with:

   - Starting price (high)
   - Ending price (low)
   - Duration (1 minute)

2. ⏳ Price decays linearly over time
3. 🎉 First bidder wins!
4. 🖼️ Winner's NFT becomes the selected ad

## 💰 Price Calculation Magic

The price drops linearly from start to end. Here's how we calculate it:

```solidity
currentPrice = startPrice - (totalPriceDiff * elapsed) / duration
```

Where:

- totalPriceDiff = startPrice - endPrice
- elapsed = current time - start time
- duration = 1 minute

### 📊 Visual Example

```
Price
   ^
   |
100| *
   |    *
 75|       *
   |          *
 50|             *
   |                *
 25|                   *
   +-----------------------> Time
   0s                   60s
```

## 🎪 Events to Watch

1. 🎯 `AuctionStarted(startPrice, endPrice, startTime, duration)`

   - Fired when operator kicks off a new auction

2. 💫 `BidPlaced(bidder, amount, tokenId)`

   - Fired when someone places a winning bid

3. 🏆 `AuctionEnded(winner, amount, tokenId)`

   - Auction complete! We have a winner!

4. 📢 `WinningAdSelected(tokenId, title, content, imageURL, publisher, price)`
   - Details about the winning ad

## 🎮 How to Participate

1. Check current price:

```solidity
getCurrentPrice()
```

2. Place a bid (must be >= current price):

```solidity
placeBid(tokenId, bidAmount)
```

## 💡 Pro Tips

- 🏃‍♂️ First valid bid wins instantly
- 💸 Bid amount must be >= current price
- 🎨 Make sure your NFT exists before bidding
- 💰 Approve tokens before bidding
- ⏰ Auction lasts exactly 1 minute

## 🚫 What Happens If...

- No bids? Operator can end auction with `endAuctionNoBids()`
- Bid too low? Transaction reverts
- Auction ended? Wait for next one!

Happy Bidding! 🎉
