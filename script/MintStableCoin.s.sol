// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/PlaceholderStableCoin.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract MintStableCoin is Script {
    // The amount to mint for each address (1000 tokens with 18 decimals)
    uint256 constant MINT_AMOUNT = 100000 * 10 ** 18;

    // Array of recipient addresses
    address[] public recipients = [
        0xbb02a9D6A71A847D587cE4Dbb92F32f79c2EfB2a,
        0xb47CFCf8181D36117142b83D31BBBF63B1b250fE,
        0xb1AfD5179ac5D755C2da5bd2F961F5520647aEB2,
        0xBd4114D7521F80C4bad67F5ECE1C843627078791
    ];

    function setUp() public { }

    function getStableCoinAddress() internal view returns (address) {
        string memory deploymentPath = string.concat(vm.projectRoot(), "/deployments/deployment.json");

        string memory json = vm.readFile(deploymentPath);
        bytes memory addressBytes = vm.parseJson(json, ".contracts.PlaceholderStableCoin.address");

        return abi.decode(addressBytes, (address));
    }

    function run() public {
        // Get deployment private key from environment
        string memory key = vm.envString("PRIVATE_KEY");
        require(bytes(key).length > 0, "Private key not found in environment");

        // Convert to bytes32 then uint256
        bytes32 parsedKey = vm.parseBytes32(key);
        uint256 deployerPrivateKey = uint256(parsedKey);

        vm.startBroadcast(deployerPrivateKey);

        address stablecoinAddress = getStableCoinAddress();
        PlaceholderStableCoin stablecoin = PlaceholderStableCoin(stablecoinAddress);

        // Calculate total amount needed
        uint256 totalMintAmount = MINT_AMOUNT * recipients.length;

        console.log("\nStarting StableCoin minting process...");
        console.log("====================================");
        console.log("StableCoin Address:", address(stablecoin));
        console.log("Mint Amount per Address:", MINT_AMOUNT / 10 ** 18, "tokens");
        console.log("Number of Recipients:", recipients.length);
        console.log("Total Mint Amount:", totalMintAmount / 10 ** 18, "tokens");
        console.log("====================================\n");

        // Mint all tokens at once
        try stablecoin.mint(totalMintAmount) {
            console.log("Successfully minted total amount:", totalMintAmount / 10 ** 18, "tokens");

            // Transfer tokens to each recipient
            for (uint256 i = 0; i < recipients.length; i++) {
                try stablecoin.transfer(recipients[i], MINT_AMOUNT) {
                    console.log("Successfully transferred", MINT_AMOUNT / 10 ** 18, "tokens to:", recipients[i]);
                } catch Error(string memory reason) {
                    console.log("Failed to transfer to", recipients[i], "- Reason:", reason);
                }
            }
        } catch Error(string memory reason) {
            console.log("Failed to mint tokens - Reason:", reason);
        }

        vm.stopBroadcast();

        // Log final summary
        console.log("\nMinting process completed!");
        console.log("====================================");

        // Save minting information to a JSON file
        string memory json = generateMintingJson(stablecoinAddress);
        writeMintingInfo(json);
    }

    // Rest of the functions remain unchanged...
    function generateMintingJson(address stablecoinAddress) internal view returns (string memory) {
        string memory recipientsJson = "";

        for (uint256 i = 0; i < recipients.length; i++) {
            recipientsJson = string.concat(
                recipientsJson,
                '{"address": "',
                vm.toString(recipients[i]),
                '", "amount": "',
                vm.toString(MINT_AMOUNT),
                '", "explorer": "https://sepolia.basescan.org/address/',
                vm.toString(recipients[i]),
                '"}'
            );

            if (i < recipients.length - 1) {
                recipientsJson = string.concat(recipientsJson, ",");
            }
        }

        return string.concat(
            "{",
            '"timestamp": ',
            vm.toString(block.timestamp),
            ",",
            '"network": ',
            vm.toString(block.chainid),
            ",",
            '"stablecoinAddress": "',
            vm.toString(stablecoinAddress),
            '",',
            '"explorer": "https://sepolia.basescan.org/address/',
            vm.toString(stablecoinAddress),
            '",',
            '"mintAmount": "',
            vm.toString(MINT_AMOUNT),
            '",',
            '"recipients": [',
            recipientsJson,
            "]",
            "}"
        );
    }

    function writeMintingInfo(string memory json) internal {
        string memory mintingPath =
            string.concat(vm.projectRoot(), "/deployments/minting_", vm.toString(block.timestamp), ".json");

        vm.createDir("deployments", true);
        vm.writeFile(mintingPath, json);
        console.log("Minting information written to:", mintingPath);
    }
}
