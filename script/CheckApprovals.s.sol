// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/PlaceholderStableCoin.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";

contract CheckApprovals is Script {
    // Array of addresses to check
    address[] public addresses = [
        0xbb02a9D6A71A847D587cE4Dbb92F32f79c2EfB2a,
        0xb47CFCf8181D36117142b83D31BBBF63B1b250fE,
        0xb1AfD5179ac5D755C2da5bd2F961F5520647aEB2,
        0xBd4114D7521F80C4bad67F5ECE1C843627078791
    ];

    function getDeployedAddresses() internal view returns (address stablecoin, address marketplace) {
        string memory deploymentPath = string.concat(vm.projectRoot(), "/deployments/deployment.json");
        string memory json = vm.readFile(deploymentPath);

        bytes memory stablecoinBytes = vm.parseJson(json, ".contracts.PlaceholderStableCoin.address");
        bytes memory marketplaceBytes = vm.parseJson(json, ".contracts.PlaceholderAdsMarketplace.address");

        return (abi.decode(stablecoinBytes, (address)), abi.decode(marketplaceBytes, (address)));
    }

    function run() public view {
        // Get deployment addresses
        (address stablecoinAddress, address marketplaceAddress) = getDeployedAddresses();
        PlaceholderStableCoin token = PlaceholderStableCoin(stablecoinAddress);

        // Header
        console2.log("\n=== Current Approvals Status ===");
        console2.log("StableCoin:", stablecoinAddress);
        console2.log("Marketplace:", marketplaceAddress);
        console2.log("================================\n");

        // Check each address
        for (uint256 i = 0; i < addresses.length; i++) {
            address currentAddress = addresses[i];

            // Get balance and allowance
            uint256 balance = token.balanceOf(currentAddress);
            uint256 allowance = token.allowance(currentAddress, marketplaceAddress);

            console2.log("Address", i + 1, "of", addresses.length);
            console2.log("Account:", currentAddress);
            console2.log("Balance:", balance / 1e18, "tokens");
            console2.log("Allowance:", allowance / 1e18, "tokens");
            console2.log("--------------------------------\n");
        }
    }
}
