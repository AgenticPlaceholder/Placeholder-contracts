// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { PlaceholderAdsMarketplace } from "../src/PlaceholderAdsMarketplace.sol";
import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/console2.sol";

contract StartAuctionScript is Script {
    using stdJson for string;

    function run() external {
        // Load deployment data
        string memory deploymentJson = vm.readFile("deployments/deployment.json");
        address marketplaceAddress = deploymentJson.readAddress(".contracts.PlaceholderAdsMarketplace.address");

        // Configure auction parameters
        uint256 startPrice = 100e18; // 1000 stable coins
        uint256 endPrice = 10e18; // 100 stable coins
        uint256 duration = 60; // 1 minute
        // Load private key for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Get marketplace contract instance
        PlaceholderAdsMarketplace marketplace = PlaceholderAdsMarketplace(marketplaceAddress);

        // Call startAuction
        marketplace.startAuction(startPrice, endPrice, duration);

        vm.stopBroadcast();

        console2.log("Auction started successfully");
        console2.log("Start Price:", startPrice);
        console2.log("End Price:", endPrice);
        console2.log("Marketplace Address:", marketplaceAddress);
    }
}
