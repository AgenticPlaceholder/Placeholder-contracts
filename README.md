Agentic Placeholder is an autonomous, blockchain-powered ad network that ensures trust, transparency, and efficiency in digital advertising.

Automated Ad Creation: AI agents interact with advertisers, generate ad content and images, and issue an NFT in exchange for ad creation.

Decentralized Ad Display: Operators provide screen space for ad placements, and publishers compete for slots through a bidding system. A bidding agent runs Dutch-style auctions, securing optimal ad slots based on predefined criteria.

Reputation-Driven System: Ads include an on-chain reputation score for publishers, along with a QR code that enables viewers to rate ads (1-5 stars) and leave feedback.

Onchain Attestation : Simple, structured, and immutable pieces of information given to the users on True Network.

COMPONENTS :

Operator Display App (Raspberry Pi + Flutter)
Runs on Flutter, deployed on a Raspberry Pi device. Listens to smart contract events for auction status updates and displays ads once a bid is placed. Reacts dynamically to state changes in real-time.

Smart Contracts (Solidity)
NFT Contract: Mints an NFT for each ad created. Bidding Contract: Implements a Dutch auction mechanism for ad slots. Token Contract: Uses PSDT (Placeholder Stable Dollar Token) as the reward and payment token. AVS FeedbackManager: Manages AVS and Eigen Layer contracts.

Mobile App (Flutter)
Allows users to connect their wallets and scan QR codes on ads. Users can rate ads (1-5 stars) and leave feedback, which gets attested on-chain via True Network. Attestations contribute to publisher reputation scores, ensuring transparent feedback.

Publisher Dashboard (Next.js + Backend APIs)
Built with Next.js for a seamless UI/UX experience. Displays bid data, and real-time updates. Backend APIs (JavaScript) connect the dashboard, display app, and mobile app. Uses WebSockets to listen for smart contract events and push updates instantly.




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
