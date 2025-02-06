// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IPlaceholderAdsNFT {
    struct AdData {
        string title;
        string content;
        string imageURL;
        address publisher;
    }

    function getAdData(uint256 tokenId) external view returns (AdData memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract PlaceholderAdsMarketplace is ReentrancyGuard {
    IPlaceholderAdsNFT public nftContract;

    // --------------------------------------
    // EVENTS
    // --------------------------------------
    event AuctionStarted(uint256 startPrice, uint256 endPrice, uint256 startTime, uint256 duration);
    event AuctionEnded(address winner, uint256 winningBid, uint256 tokenId);
    event BidPlaced(address bidder, uint256 bidAmount, uint256 tokenId);
    event ProofSubmitted(uint256 tokenId, bytes32 proofHash);
    event PaymentClaimed(uint256 tokenId, uint256 amount);
    event WinningAdSelected(
        uint256 indexed tokenId,
        string title,
        string content,
        string imageURL,
        address indexed publisher,
        uint256 bidAmount
    );
    // --------------------------------------
    // STORAGE
    // --------------------------------------

    address public operator;
    IERC20 public biddingToken;

    struct Auction {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 duration;
        address winner;
        uint256 winningBid;
        uint256 winningTokenId;
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
            block.timestamp >= currentAuction.startTime
                && block.timestamp <= currentAuction.startTime + currentAuction.duration,
            "Auction not active"
        );
        require(!currentAuction.ended, "Auction already ended");
        _;
    }

    // --------------------------------------
    // CONSTRUCTOR
    // --------------------------------------
    constructor(address _biddingToken, address _nftContract) {
        require(_biddingToken != address(0), "Invalid token address");
        operator = msg.sender;
        biddingToken = IERC20(_biddingToken);
        nftContract = IPlaceholderAdsNFT(_nftContract);
    }

    // --------------------------------------
    // AUCTION LOGIC
    // --------------------------------------
    function startAuction(uint256 _startPrice, uint256 _endPrice) external onlyOperator {
        // Simplified auction state check
        require(currentAuction.startTime == 0 || currentAuction.ended, "Existing auction not ended");

        // Price validations
        require(_startPrice > 0, "Start price must be greater than 0");
        require(_endPrice > 0, "End price must be greater than 0");
        require(_endPrice <= _startPrice, "End price must be <= start price");

        // Ensure significant price difference to avoid rounding issues
        require(_startPrice - _endPrice >= _startPrice / 100, "Price difference too small");

        uint256 startTime = block.timestamp;
        uint256 duration = 5 minutes;

        currentAuction = Auction({
            startPrice: _startPrice,
            endPrice: _endPrice,
            startTime: startTime,
            duration: duration,
            winner: address(0),
            winningBid: 0,
            winningTokenId: 0,
            proofSubmitted: false,
            claimed: false,
            ended: false
        });

        emit AuctionStarted(_startPrice, _endPrice, startTime, duration);
    }

    function getCurrentPrice() public view returns (uint256) {
        if (currentAuction.startTime == 0) {
            revert("No active auction");
        }

        if (currentAuction.ended) {
            revert("Auction ended");
        }

        uint256 elapsed = block.timestamp - currentAuction.startTime;

        if (block.timestamp < currentAuction.startTime) {
            return currentAuction.startPrice;
        }

        if (elapsed >= currentAuction.duration) {
            return currentAuction.endPrice;
        }

        // Rearrange calculation to do multiplication before division
        // (totalPriceDiff * elapsed) / duration
        uint256 totalPriceDiff = currentAuction.startPrice - currentAuction.endPrice;

        // Use unchecked for gas optimization since we know these values are bounded
        unchecked {
            // Calculate price drop with maximum precision
            uint256 currentPriceDrop = (totalPriceDiff * elapsed) / currentAuction.duration;
            return currentAuction.startPrice - currentPriceDrop;
        }
    }

    function placeBid(uint256 _tokenId, uint256 _bidAmount) external nonReentrant auctionActive {
        // Require he owns the tokenID
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You don't own this token");
        uint256 currentPrice = getCurrentPrice();
        require(_bidAmount >= currentPrice, "Bid below current price");
        require(_bidAmount > 0, "Bid amount must be greater than 0");
        require(currentAuction.winner == address(0), "Auction already has a winner");

        // Check and transfer tokens
        require(biddingToken.allowance(msg.sender, address(this)) >= _bidAmount, "Insufficient allowance");
        require(biddingToken.balanceOf(msg.sender) >= _bidAmount, "Insufficient balance");
        require(biddingToken.transferFrom(msg.sender, address(this), _bidAmount), "Token transfer failed");

        // Update auction state
        currentAuction.winner = msg.sender;
        currentAuction.winningBid = _bidAmount;
        currentAuction.winningTokenId = _tokenId;
        currentAuction.ended = true;

        IPlaceholderAdsNFT.AdData memory adData = nftContract.getAdData(_tokenId);

        emit BidPlaced(msg.sender, _bidAmount, _tokenId);
        emit AuctionEnded(msg.sender, _bidAmount, _tokenId);
        emit WinningAdSelected(
            _tokenId, adData.title, adData.content, adData.imageURL, adData.publisher, currentAuction.winningBid
        );
    }

    function endAuctionNoBids() external onlyOperator {
        require(!currentAuction.ended, "Auction already ended");
        require(block.timestamp > currentAuction.startTime + currentAuction.duration, "Auction not finished");
        require(currentAuction.winner == address(0), "Winner already exists");

        currentAuction.ended = true;
        // Possibly emit an AuctionCancelled or AuctionNoBids event
    }

    function submitProof(uint256 _tokenId, bytes32 _proofHash) external onlyOperator {
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
        require(biddingToken.transfer(operator, currentAuction.winningBid), "Transfer failed");

        emit PaymentClaimed(_tokenId, currentAuction.winningBid);
    }

    // --------------------------------------
    // VIEW / HELPER FUNCTIONS
    // --------------------------------------

    function getWinningAdData()
        external
        view
        returns (string memory title, string memory content, string memory imageURL, address publisher, uint256 tokenId)
    {
        require(currentAuction.ended, "No winning ad yet");
        require(currentAuction.winner != address(0), "No winner");

        // Get the winning token ID
        uint256 winningTokenId = currentAuction.winningTokenId;

        // Fetch ad data from NFT contract
        IPlaceholderAdsNFT.AdData memory adData = nftContract.getAdData(winningTokenId);

        return (adData.title, adData.content, adData.imageURL, adData.publisher, winningTokenId);
    }

    function getAuctionConfig()
        external
        view
        returns (uint256 startPrice, uint256 endPrice, uint256 duration, uint256 startTime)
    {
        return (currentAuction.startPrice, currentAuction.endPrice, currentAuction.duration, currentAuction.startTime);
    }

    function getAuctionState() external view returns (uint256 currentPrice, bool isActive, uint256 timeRemaining) {
        Auction storage a = currentAuction;
        bool active = a.startTime != 0 && !a.ended && block.timestamp >= a.startTime
            && block.timestamp <= a.startTime + a.duration;

        uint256 price = active ? getCurrentPrice() : 0;
        uint256 remaining = active ? a.startTime + a.duration - block.timestamp : 0;

        return (price, active, remaining);
    }

    function getWinnerInfo() external view returns (address winner, uint256 winningBid, uint256 winningTokenId) {
        return (currentAuction.winner, currentAuction.winningBid, currentAuction.winningTokenId);
    }

    function getAdminState() external view returns (bool proofSubmitted, bool claimed, bool ended) {
        return (currentAuction.proofSubmitted, currentAuction.claimed, currentAuction.ended);
    }

    function changeOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "Invalid operator");
        operator = _newOperator;
    }
}
