// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PlaceholderAdsNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 private _nextTokenId;

    struct AdData {
        string title;
        string content;
        string imageURL;
        address publisher;
    }

    mapping(uint256 => AdData) private _adMetadata;

    event AdNFTMinted(address to, uint256 tokenId, AdData data);

    constructor() ERC721("PlaceholderAds", "PHA") Ownable(msg.sender) { }

    /**
     * @dev Mints a new AdNFT with complete metadata
     * @param to Receiver address
     * @param title Advertisement title
     * @param text Main ad content
     * @param imageURL URL to visual asset (PNG/JPEG/GIF)
     */
    function createAd(address to, string memory title, string memory text, string memory imageURL)
        public
        returns (uint256)
    {
        uint256 newTokenId = _nextTokenId++;

        _safeMint(to, newTokenId);

        _adMetadata[newTokenId] = AdData({ title: title, content: text, imageURL: imageURL, publisher: to });

        emit AdNFTMinted(to, newTokenId, _adMetadata[newTokenId]);

        return newTokenId;
    }

    /**
     * @dev Generates standards-compliant metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Get metadata from storage
        AdData memory data = _adMetadata[tokenId];

        // Convert address to a string (Ensures 0x format)
        string memory publisherAddress = Strings.toHexString(uint160(data.publisher), 20);

        // Build metadata JSON (Properly formatted)
        bytes memory json = abi.encodePacked(
            "{",
            '"name": "',
            data.title,
            '",',
            '"description": "',
            data.title,
            " - ",
            data.content,
            '",',
            '"image": "',
            data.imageURL,
            '",',
            '"attributes": [',
            '{"trait_type": "Publisher", "value": "',
            publisherAddress,
            '"}' "]",
            "}"
        );

        // Encode JSON in Base64
        string memory base64Json = Base64.encode(json);

        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    // Getters for external access
    function getAdData(uint256 tokenId) public view returns (AdData memory) {
        return _adMetadata[tokenId];
    }
}
