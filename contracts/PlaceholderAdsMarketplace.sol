// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PlaceholderAdsMarketplace
 * @dev Simplified contract to conduct a single-slot Dutch Auction among multiple advertisers.
 *      - Only one Trusted Operator (owner) is allowed to start/end auctions.
 *      - Multiple publishers (advertisers) can place bids (sending ETH).
 *      - The first bid >= the current Dutch Auction price wins.
 */
contract PlaceholderAdsMarketplace {
    // --------------------------------------
    // EVENTS
    // --------------------------------------
    event AuctionStarted(
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime,
        uint256 duration
    );
    event AuctionEnded(
        address winner,
        uint256 winningBid,
        uint256 tokenId
    );
    event BidPlaced(
        address bidder,
        uint256 bidAmount,
        uint256 tokenId
    );

    // --------------------------------------
    // STORAGE
    // --------------------------------------

    address public operator;  // Trusted Operator (e.g., the entity that controls the display)
    
    // Data structure for a single Dutch Auction
    struct Auction {
        uint256 startPrice;     // Price at which the auction starts
        uint256 endPrice;       // Minimum price the auction can drop to
        uint256 startTime;      // Timestamp when the auction officially begins
        uint256 duration;       // How long it takes to go from startPrice down to endPrice
        address winner;         // Address of the winning bidder
        uint256 winningBid;     // Amount (in wei) that the winner paid
        uint256 winningTokenId; // The NFT ID the winner wants to display
        bool ended;             // Marks if the auction ended
    }

    // We assume only ONE slot/auction for simplicity
    Auction public currentAuction;

    // --------------------------------------
    // MODIFIERS
    // --------------------------------------
    modifier onlyOperator() {
        require(msg.sender == operator, "Not the operator");
        _;
    }

    modifier auctionActive() {
        require(
            block.timestamp >= currentAuction.startTime &&
            block.timestamp <= currentAuction.startTime + currentAuction.duration,
            "Auction not active"
        );
        require(!currentAuction.ended, "Auction already ended");
        _;
    }

    // --------------------------------------
    // CONSTRUCTOR
    // --------------------------------------
    constructor() {
        // The deployer is the Trusted Operator
        operator = msg.sender;
    }

    // --------------------------------------
    // AUCTION LOGIC
    // --------------------------------------

    /**
     * @dev Operator starts a Dutch auction by setting the parameters.
     * @param _startPrice Price at which the auction starts.
     * @param _endPrice Lowest price the auction can drop to.
     * @param _startTime Timestamp at which the auction starts.
     * @param _duration How many seconds from startPrice to endPrice.
     *
     * NOTE: For a typical immediate start, set _startTime = block.timestamp.
     */
    function startAuction(
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _startTime,
        uint256 _duration
    ) external onlyOperator {
        require(_endPrice <= _startPrice, "endPrice must be <= startPrice");
        require(_duration > 0, "Duration must be > 0");

        // Initialize a new Auction
        currentAuction = Auction({
            startPrice: _startPrice,
            endPrice: _endPrice,
            startTime: _startTime,
            duration: _duration,
            winner: address(0),
            winningBid: 0,
            winningTokenId: 0,
            ended: false
        });

        emit AuctionStarted(_startPrice, _endPrice, _startTime, _duration);
    }

    /**
     * @dev Computes the current price of the Dutch Auction.
     *      Price decreases linearly from startPrice to endPrice over 'duration'.
     */
    function getCurrentPrice() public view returns (uint256) {
        if (
            block.timestamp <= currentAuction.startTime ||
            currentAuction.startTime == 0 ||
            currentAuction.ended
        ) {
            // Before or after the auction time, return the startPrice.
            return currentAuction.startPrice;
        }

        // If time has already ended, return the endPrice
        uint256 elapsed = block.timestamp - currentAuction.startTime;
        if (elapsed >= currentAuction.duration) {
            return currentAuction.endPrice;
        }

        // Calculate price decay
        // price = startPrice - ( (startPrice - endPrice) * elapsed / duration )
        uint256 totalPriceDiff = currentAuction.startPrice - currentAuction.endPrice;
        uint256 currentPriceDrop = (totalPriceDiff * elapsed) / currentAuction.duration;
        uint256 currentPrice = currentAuction.startPrice - currentPriceDrop;

        return currentPrice;
    }

    /**
     * @dev Places a bid. First bidder who sends >= currentPrice wins immediately.
     * @param _tokenId The NFT (from PlaceholderAdsNFT) that the publisher wants to display upon winning.
     */
    function placeBid(uint256 _tokenId) external payable auctionActive {
        uint256 price = getCurrentPrice();
        require(msg.value >= price, "Bid not high enough");

        // Record the winner
        currentAuction.winner = msg.sender;
        currentAuction.winningBid = msg.value;
        currentAuction.winningTokenId = _tokenId;
        currentAuction.ended = true; // Auction ends immediately after a valid bid

        emit BidPlaced(msg.sender, msg.value, _tokenId);
        emit AuctionEnded(msg.sender, msg.value, _tokenId);

        // (Simplest approach) Transfer funds to the operator (or hold it in the contract).
        // If you'd like to pay it out to the publisher or do profit-sharing, add that logic here:
        payable(operator).transfer(msg.value);
    }

    /**
     * @dev Operator can end the auction in case no one bids and time is over, or to force-end the auction.
     *      This is optional since the auction is automatically ended upon a successful bid,
     *      but you may want to allow the operator to finalize or do an emergency stop.
     */
    function endAuction() external onlyOperator {
        require(!currentAuction.ended, "Auction already ended");

        // If time hasn't ended but operator wants to end, that's an operator override
        currentAuction.ended = true;

        emit AuctionEnded(address(0), 0, 0); // Indicate no winner
    }

    // --------------------------------------
    // VIEW / HELPER FUNCTIONS
    // --------------------------------------

    /**
     * @dev Returns information about the current auction state.
     */
    function getAuctionInfo()
        external
        view
        returns (
            uint256 startPrice,
            uint256 endPrice,
            uint256 startTime,
            uint256 duration,
            address winner,
            uint256 winningBid,
            uint256 winningTokenId,
            bool ended
        )
    {
        Auction memory a = currentAuction;
        return (
            a.startPrice,
            a.endPrice,
            a.startTime,
            a.duration,
            a.winner,
            a.winningBid,
            a.winningTokenId,
            a.ended
        );
    }

    /**
     * @dev Allows the operator to change to a new operator (if needed).
     */
    function changeOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "Invalid operator");
        operator = _newOperator;
    }
}
