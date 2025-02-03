// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IPlaceholderAdsNFT {
    struct AdData {
        string title;
        string content;
        string imageURL;
        address publisher;
    }
    
    function getAdData(uint256 tokenId) external view returns (AdData memory);
}

contract AdSlotMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _slotIds;
    address public immutable adNFTContract;
    
    struct Slot {
        uint256 adId;
        string title;
        string content;
        string imageURL;
        address publisher;
    }

    mapping(uint256 => Slot) public slots;

    event SlotCreated(uint256 slotId);
    event SlotUpdated(uint256 slotId, uint256 adId);

    constructor(address _adNFTAddress) 
        ERC721("AdSlot", "ASLOT") 
        Ownable(msg.sender) 
    {
        adNFTContract = _adNFTAddress;
    }

    // Operator creates new ad slot
    function createSlot() external onlyOwner {
        _slotIds.increment();
        uint256 newSlotId = _slotIds.current();
        _mint(owner(), newSlotId);
        emit SlotCreated(newSlotId);
    }

    // Operator updates slot with winning ad (after off-chain auction)
    function updateSlotWithAd(uint256 slotId, uint256 adId) external onlyOwner {
        require(ownerOf(slotId) == owner(), "Invalid slot");
        
        IPlaceholderAdsNFT.AdData memory adData = 
            IPlaceholderAdsNFT(adNFTContract).getAdData(adId);

        slots[slotId] = Slot({
            adId: adId,
            title: adData.title,
            content: adData.content,
            imageURL: adData.imageURL,
            publisher: adData.publisher
        });

        emit SlotUpdated(slotId, adId);
    }

    // Get current ad data for display
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        
        Slot memory slot = slots[tokenId];
        string memory publisher = Strings.toHexString(slot.publisher);

        bytes memory metadata = abi.encodePacked(
            '{"name": "Ad Slot #', tokenId.toString(), '",',
            '"description": "Current ad: ', slot.title, '",',
            '"image": "', slot.imageURL, '",',
            '"attributes": [',
                '{"trait_type": "Title", "value": "', slot.title, '"},',
                '{"trait_type": "Publisher", "value": "', publisher, '"},',
                '{"trait_type": "Ad ID", "value": "', slot.adId.toString(), '"}',
            ']}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }
}