// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { PlaceholderAdsMarketplace } from "../src/PlaceholderAdsMarketplace.sol";
import { PlaceholderAdsNFT } from "../src/PlaceholderAdsNFT.sol";
import { PlaceholderStableCoin } from "../src/PlaceholderStableCoin.sol";
import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/console2.sol";

contract PlaceBidScript is Script {
    using stdJson for string;

    function run() external {
        // Load deployment data
        string memory deploymentJson = vm.readFile("deployments/deployment.json");
        address marketplaceAddress = deploymentJson.readAddress(".contracts.PlaceholderAdsMarketplace.address");
        address stablecoinAddress = deploymentJson.readAddress(".contracts.PlaceholderStableCoin.address");
        address nftAddress = deploymentJson.readAddress(".contracts.PlaceholderAdsNFT.address");

        // Get contract instances
        PlaceholderAdsMarketplace marketplace = PlaceholderAdsMarketplace(marketplaceAddress);
        PlaceholderStableCoin stablecoin = PlaceholderStableCoin(stablecoinAddress);
        PlaceholderAdsNFT nft = PlaceholderAdsNFT(nftAddress);

        // Get current auction state
        (uint256 currentPrice, bool isActive, uint256 timeRemaining) = marketplace.getAuctionState();
        require(isActive, "No active auction");

        console2.log("Current auction price:", currentPrice);
        console2.log("Time remaining:", timeRemaining);

        vm.startBroadcast();

        // Get owned token ID
        uint256[] memory ownedTokens = nft.getOwnedTokens(msg.sender);
        require(ownedTokens.length > 0, "No tokens owned");
        // Get the last token ID from the array
        uint256 tokenId = ownedTokens[ownedTokens.length - 1];
        console2.log("Total owned tokens:", ownedTokens.length);
        console2.log("Bidding with last token ID:", tokenId);

        console2.log("Bidding with token ID:", tokenId);

        // First approve the marketplace to spend tokens
        uint256 bidAmount = currentPrice;
        stablecoin.approve(marketplaceAddress, bidAmount);

        // Place the bid
        try marketplace.placeBid(tokenId, bidAmount) {
            console2.log("Bid placed successfully!");
            console2.log("Token ID:", tokenId);
            console2.log("Bid amount:", bidAmount);
        } catch Error(string memory reason) {
            console2.log("Bid failed:", reason);
        } catch {
            console2.log("Bid failed with unknown error");
        }

        vm.stopBroadcast();
    }
}
