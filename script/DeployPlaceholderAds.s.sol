// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PlaceholderAdsNFT.sol";
import "../src/PlaceholderAdsMarketplace.sol";
import "../src/PlaceholderStableCoin.sol";

contract DeployPlaceholderAds is Script {
    PlaceholderAdsNFT public nft;
    PlaceholderAdsMarketplace public marketplace;
    PlaceholderStableCoin public stablecoin;

    function setUp() public {}

    function run() public {
        // Get deployment private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts in correct order
        // 1. First deploy the NFT contract
        nft = new PlaceholderAdsNFT();
        console.log("PlaceholderAdsNFT deployed to:", address(nft));

        // 2. Deploy the stablecoin
        stablecoin = new PlaceholderStableCoin();
        console.log("PlaceholderStableCoin deployed to:", address(stablecoin));

        // 3. Deploy the marketplace with required parameters
        marketplace = new PlaceholderAdsMarketplace(
            address(nft), // NFT contract address
            address(stablecoin) // Bidding token address
        );
        console.log("PlaceholderAdsMarketplace deployed to:", address(marketplace));

        vm.stopBroadcast();

        // Log deployment details
        console.log("\nDeployment Summary:");
        console.log("==================");
        console.log("Network:", block.chainid);
        console.log("PlaceholderAdsNFT:", address(nft));
        console.log("PlaceholderStableCoin:", address(stablecoin));
        console.log("PlaceholderAdsMarketplace:", address(marketplace));
    }
}
