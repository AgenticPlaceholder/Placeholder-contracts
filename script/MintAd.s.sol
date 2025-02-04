// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PlaceholderAdsNFT } from "../src/PlaceholderAdsNFT.sol";
import { console2 } from "forge-std/Console2.sol";
import { Script } from "forge-std/Script.sol";

contract MintAdScript is Script {
    function run() external {
        // Load contract address from deployment file
        string memory json = vm.readFile("deployments/deployment.json");
        address nftAddress = abi.decode(vm.parseJson(json, ".contracts.PlaceholderAdsNFT.address"), (address));

        console2.log("Using NFT contract at:", nftAddress);

        vm.startBroadcast();

        PlaceholderAdsNFT nft = PlaceholderAdsNFT(nftAddress);

        uint256 tokenId = nft.createAd(
            0xbb02a9D6A71A847D587cE4Dbb92F32f79c2EfB2a,
            "Sample Advertisement",
            "This is a test advertisement minted via Foundry script",
            "https://placeholderads.s3.ap-south-1.amazonaws.com/ad-images/1738575381353-6912.png"
        );

        console2.log("Successfully minted Ad NFT with token ID:", tokenId);

        vm.stopBroadcast();
    }
}
