// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PlaceholderAdsMarketplace is ReentrancyGuard {
    // --------------------------------------
    // EVENTS
    // --------------------------------------
    event AuctionStarted(
        uint256 startPrice,
        uint256 endPrice,
        uint256 startTime,
        uint256 duration
    );
    event AuctionEnded(address winner, uint256 winningBid, uint256 tokenId);
    event BidPlaced(address bidder, uint256 bidAmount, uint256 tokenId);
    event ProofSubmitted(uint256 tokenId, bytes32 proofHash);
    event PaymentClaimed(uint256 tokenId, uint256 amount);

    // --------------------------------------
    // STORAGE
    // --------------------------------------
    address public operator;
    IERC20 public biddingToken; // The ERC20 token used for bidding
    uint256 public constant MINIMUM_BID_PERIOD = 20 seconds;
    struct Auction {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 duration;
        address winner;
        uint256 winningBid;
        uint256 winningTokenId;
        uint256 lastBidTime;
        bool proofSubmitted;
        bool claimed;
        bool ended;
    }

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
                block.timestamp <=
                currentAuction.startTime + currentAuction.duration,
            "Auction not active"
        );
        require(!currentAuction.ended, "Auction already ended");
        _;
    }

    // --------------------------------------
    // CONSTRUCTOR
    // --------------------------------------
    constructor(address _biddingToken) {
        require(_biddingToken != address(0), "Invalid token address");
        operator = msg.sender;
        biddingToken = IERC20(_biddingToken);
    }

    // --------------------------------------
    // AUCTION LOGIC
    // --------------------------------------
    function startAuction(uint256 _startPrice, uint256 _endPrice)
        external
        onlyOperator
    {
        require(_startPrice > 0, "Start price must be greater than 0"); // Added
        require(_endPrice <= _startPrice, "End price must be <= start price");
        uint256 startTime = block.timestamp;
        uint256 duration = 5 minutes; // Fixed 3-minute duration

        currentAuction = Auction({
            startPrice: _startPrice,
            endPrice: _endPrice,
            startTime: startTime,
            duration: duration,
            winner: address(0),
            winningBid: 0,
            winningTokenId: 0,
            lastBidTime: 0,
            proofSubmitted: false,
            claimed: false,
            ended: false
        });

        emit AuctionStarted(_startPrice, _endPrice, startTime, duration);
    }

    function getCurrentPrice() public view returns (uint256) {
        if (
            block.timestamp < currentAuction.startTime ||
            currentAuction.startTime == 0 ||
            currentAuction.ended
        ) {
            return currentAuction.startPrice;
        }

        uint256 elapsed = block.timestamp - currentAuction.startTime;
        if (elapsed >= currentAuction.duration) {
            return currentAuction.endPrice;
        }

        // Calculate price drop using fixed-point arithmetic
        uint256 totalPriceDiff = currentAuction.startPrice -
            currentAuction.endPrice;
        uint256 currentPriceDrop = (totalPriceDiff * elapsed * 1e18) /
            currentAuction.duration;
        currentPriceDrop = currentPriceDrop / 1e18; // Scale back after division

        return currentAuction.startPrice - currentPriceDrop;
    }

    function placeBid(uint256 _tokenId, uint256 _bidAmount)
        external
        nonReentrant
        auctionActive
    {
        uint256 currentPrice = getCurrentPrice();
        require(_bidAmount >= currentPrice, "Bid below current price");
        require(_bidAmount > 0, "Bid amount must be greater than 0");

        // If bid equals start price, end auction immediately
        if (_bidAmount >= currentAuction.startPrice) {
            require(
                biddingToken.allowance(msg.sender, address(this)) >= _bidAmount,
                "Insufficient allowance"
            );
            require(
                biddingToken.balanceOf(msg.sender) >= _bidAmount,
                "Insufficient balance"
            );
            require(
                biddingToken.transferFrom(
                    msg.sender,
                    address(this),
                    _bidAmount
                ),
                "Token transfer failed"
            );

            currentAuction.winner = msg.sender;
            currentAuction.winningBid = _bidAmount;
            currentAuction.winningTokenId = _tokenId;
            currentAuction.ended = true;

            emit BidPlaced(msg.sender, _bidAmount, _tokenId);
            emit AuctionEnded(msg.sender, _bidAmount, _tokenId);
            return;
        }

        // Regular bid - must be higher than current highest bid
        if (currentAuction.winningBid > 0) {
            require(
                _bidAmount > currentAuction.winningBid,
                "Must bid higher than current bid"
            );
            require(
                block.timestamp >=
                    currentAuction.lastBidTime + MINIMUM_BID_PERIOD,
                "Minimum bid period not elapsed"
            );
        }

        require(
            biddingToken.allowance(msg.sender, address(this)) >= _bidAmount,
            "Insufficient allowance"
        );
        require(
            biddingToken.balanceOf(msg.sender) >= _bidAmount,
            "Insufficient balance"
        );
        require(
            biddingToken.transferFrom(msg.sender, operator, _bidAmount),
            "Token transfer failed"
        );

        currentAuction.winner = msg.sender;
        currentAuction.winningBid = _bidAmount;
        currentAuction.winningTokenId = _tokenId;
        currentAuction.lastBidTime = block.timestamp;

        emit BidPlaced(msg.sender, _bidAmount, _tokenId);
    }

    function submitProof(uint256 _tokenId, bytes32 _proofHash)
        external
        onlyOperator
    {
        require(currentAuction.ended, "Auction not ended");
        require(currentAuction.winningTokenId == _tokenId, "Invalid token ID");
        require(!currentAuction.proofSubmitted, "Proof already submitted");

        currentAuction.proofSubmitted = true;
        emit ProofSubmitted(_tokenId, _proofHash);
    }

    // New function for claiming payment
    function claimPayment(uint256 _tokenId) external onlyOperator {
        require(currentAuction.ended, "Auction not ended");
        require(currentAuction.proofSubmitted, "Proof not submitted");
        require(!currentAuction.claimed, "Payment already claimed");
        require(currentAuction.winningTokenId == _tokenId, "Invalid token ID");

        currentAuction.claimed = true;
        require(
            biddingToken.transfer(operator, currentAuction.winningBid),
            "Transfer failed"
        );

        emit PaymentClaimed(_tokenId, currentAuction.winningBid);
    }

    // --------------------------------------
    // VIEW / HELPER FUNCTIONS
    // --------------------------------------
    function getAuctionInfo()
        external
        view
        returns (
            uint256 startPrice,
            uint256 endPrice,
            uint256 currentPrice,
            uint256 startTime,
            uint256 duration,
            address winner,
            uint256 winningBid,
            uint256 winningTokenId,
            uint256 lastBidTime,
            bool proofSubmitted,
            bool claimed,
            bool ended        )
    {
        Auction memory a = currentAuction;
        uint256 CurrentPrice = getCurrentPrice();
        return (
            a.startPrice,
            a.endPrice,
            CurrentPrice,
            a.startTime,
            a.duration,
            a.winner,
            a.winningBid,
            a.winningTokenId,
            a.lastBidTime,
            a.proofSubmitted,
            a.claimed,
            a.ended
        );
    }

    function changeOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "Invalid operator");
        operator = _newOperator;
    }
}
