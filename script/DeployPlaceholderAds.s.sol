// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/PlaceholderAdsMarketplace.sol";
import "../src/PlaceholderAdsNFT.sol";
import "../src/PlaceholderStableCoin.sol";
import "forge-std/Script.sol";

contract DeployPlaceholderAds is Script {
    PlaceholderAdsNFT public nft;
    PlaceholderAdsMarketplace public marketplace;
    PlaceholderStableCoin public stablecoin;

    function setUp() public { }

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
            address(stablecoin), // Bidding token address
            address(nft) // NFT contract
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
        // Generate and write deployment information to JSON file
        string memory json = generateDeploymentJson();
        writeDeploymentInfo(json);
    }

    function generateDeploymentJson() internal view returns (string memory) {
        return string.concat(
            "{",
            '"network": ',
            vm.toString(block.chainid),
            ",",
            '"contracts": {',
            '"PlaceholderAdsNFT": {',
            '"address": "',
            vm.toString(address(nft)),
            '",',
            '"explorer": "https://sepolia.basescan.org/address/',
            vm.toString(address(nft)),
            '",',
            '"deployedAt": ',
            vm.toString(block.timestamp),
            "},",
            '"PlaceholderStableCoin": {',
            '"address": "',
            vm.toString(address(stablecoin)),
            '",',
            '"explorer": "https://sepolia.basescan.org/address/',
            vm.toString(address(stablecoin)),
            '",',
            '"deployedAt": ',
            vm.toString(block.timestamp),
            "},",
            '"PlaceholderAdsMarketplace": {',
            '"address": "',
            vm.toString(address(marketplace)),
            '",',
            '"explorer": "https://sepolia.basescan.org/address/',
            vm.toString(address(marketplace)),
            '",',
            '"deployedAt": ',
            vm.toString(block.timestamp),
            ",",
            '"constructorArgs": {',
            '"nft": "',
            vm.toString(address(nft)),
            '",',
            '"stablecoin": "',
            vm.toString(address(stablecoin)),
            '"',
            "}",
            "}",
            "}",
            "}"
        );
    }

    function writeDeploymentInfo(string memory json) internal {
        string memory deploymentPath = string.concat(vm.projectRoot(), "/deployments/", "deployment.json");

        // Create deployments directory if it doesn't exist
        vm.createDir("deployments", true);

        // Write the JSON to file
        vm.writeFile(deploymentPath, json);

        console.log("\nDeployment information written to:", deploymentPath);
    }
}
