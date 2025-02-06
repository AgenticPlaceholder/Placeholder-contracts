// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/PlaceholderStableCoin.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract ApproveMarketplace is Script {
    // The amount to approve (1000 tokens with 18 decimals)
    uint256 constant APPROVAL_AMOUNT = 1000 * 10 ** 18;

    // Array of addresses to approve from
    address[] public addresses = [
        0xbb02a9D6A71A847D587cE4Dbb92F32f79c2EfB2a,
        0xb47CFCf8181D36117142b83D31BBBF63B1b250fE,
        0xb1AfD5179ac5D755C2da5bd2F961F5520647aEB2,
        0xBd4114D7521F80C4bad67F5ECE1C843627078791
    ];

    function getDeployedAddresses() internal view returns (address stablecoin, address marketplace) {
        string memory deploymentPath = string.concat(vm.projectRoot(), "/deployments/deployment.json");

        string memory json = vm.readFile(deploymentPath);

        // Get stablecoin address
        bytes memory stablecoinBytes = vm.parseJson(json, ".contracts.PlaceholderStableCoin.address");
        stablecoin = abi.decode(stablecoinBytes, (address));

        // Get marketplace address
        bytes memory marketplaceBytes = vm.parseJson(json, ".contracts.PlaceholderAdsMarketplace.address");
        marketplace = abi.decode(marketplaceBytes, (address));
    }

    function processPrivateKey(string memory rawKey) public pure returns (uint256) {
        bytes memory keyBytes = bytes(rawKey);

        // Remove "0x" prefix if present
        if (keyBytes.length >= 2 && keyBytes[0] == "0" && keyBytes[1] == "x") {
            string memory stripped = "";
            for (uint256 i = 2; i < keyBytes.length; i++) {
                stripped = string.concat(stripped, string(abi.encodePacked(keyBytes[i])));
            }
            rawKey = stripped;
        }

        // Add "0x" prefix for proper parsing
        return vm.parseUint(string.concat("0x", rawKey));
    }

    function run() public {
        // Get contract addresses from deployment file
        (address stablecoinAddress, address marketplaceAddress) = getDeployedAddresses();
        PlaceholderStableCoin stablecoin = PlaceholderStableCoin(stablecoinAddress);

        console.log("\nStarting marketplace approval process...");
        console.log("====================================");
        console.log("StableCoin Address:", stablecoinAddress);
        console.log("Marketplace Address:", marketplaceAddress);
        console.log("Approval Amount per Address:", APPROVAL_AMOUNT / 10 ** 18, "tokens");
        console.log("Number of Addresses:", addresses.length);
        console.log("====================================\n");

        // Process approvals for each address
        for (uint256 i = 0; i < addresses.length; i++) {
            string memory envKey = string.concat("PRIVATE_KEY_", vm.toString(i + 1));

            // Get private key from environment
            string memory rawKey;
            try vm.envString(envKey) returns (string memory key) {
                rawKey = key;
            } catch {
                console.log("Failed to read private key from environment variable:", envKey);
                continue;
            }

            // Parse private key
            uint256 privateKey;
            try this.processPrivateKey(rawKey) returns (uint256 key) {
                privateKey = key;
            } catch {
                console.log("Failed to parse private key for address:", addresses[i]);
                continue;
            }

            // Start broadcasting transactions for this address
            vm.startBroadcast(privateKey);

            try stablecoin.approve(marketplaceAddress, APPROVAL_AMOUNT) {
                console.log(
                    "Successfully approved marketplace for",
                    APPROVAL_AMOUNT / 10 ** 18,
                    "tokens from address:",
                    addresses[i]
                );
            } catch Error(string memory reason) {
                console.log("Failed to approve for address", addresses[i], "- Reason:", reason);
            }

            vm.stopBroadcast();
        }

        // Log final summary
        console.log("\nApproval process completed!");
        console.log("====================================");

        // Save approval information to a JSON file
        string memory json = generateApprovalJson(stablecoinAddress, marketplaceAddress);
        writeApprovalInfo(json);
    }

    function generateApprovalJson(address stablecoinAddress, address marketplaceAddress)
        internal
        view
        returns (string memory)
    {
        string memory approvalsJson = "";

        for (uint256 i = 0; i < addresses.length; i++) {
            approvalsJson = string.concat(
                approvalsJson,
                '{"address": "',
                vm.toString(addresses[i]),
                '", "amount": "',
                vm.toString(APPROVAL_AMOUNT),
                '", "explorer": "https://sepolia.basescan.org/address/',
                vm.toString(addresses[i]),
                '"}'
            );

            if (i < addresses.length - 1) {
                approvalsJson = string.concat(approvalsJson, ",");
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
            '"marketplaceAddress": "',
            vm.toString(marketplaceAddress),
            '",',
            '"approvalAmount": "',
            vm.toString(APPROVAL_AMOUNT),
            '",',
            '"approvals": [',
            approvalsJson,
            "]",
            "}"
        );
    }

    function writeApprovalInfo(string memory json) internal {
        string memory approvalPath =
            string.concat(vm.projectRoot(), "/deployments/approvals_", vm.toString(block.timestamp), ".json");

        vm.createDir("deployments", true);
        vm.writeFile(approvalPath, json);
        console.log("Approval information written to:", approvalPath);
    }
}
