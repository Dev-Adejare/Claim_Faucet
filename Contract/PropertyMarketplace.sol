// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PropertyMarketplace is ERC1155Holder, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC1155 public propertyToken;
    
    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 pricePerToken;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    event ListingCreated(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 amount, uint256 pricePerToken);
    event ListingCancelled(uint256 indexed listingId);
    event TokensPurchased(uint256 indexed listingId, address indexed buyer, uint256 amount, uint256 totalPrice);

    constructor(address _propertyTokenAddress) {
        propertyToken = IERC1155(_propertyTokenAddress);
    }

    function createListing(uint256 tokenId, uint256 amount, uint256 pricePerToken) external {
        require(amount > 0, "Amount must be greater than 0");
        require(pricePerToken > 0, "Price must be greater than 0");
        require(propertyToken.balanceOf(msg.sender, tokenId) >= amount, "Insufficient token balance");

        listingCounter = listingCounter.add(1);
        listings[listingCounter] = Listing({
            seller: msg.sender,
            tokenId: tokenId,
            amount: amount,
            pricePerToken: pricePerToken,
            active: true
        });

        propertyToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        emit ListingCreated(listingCounter, msg.sender, tokenId, amount, pricePerToken);
    }

    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing is not active");
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        listing.active = false;
        propertyToken.safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.amount, "");

        emit ListingCancelled(listingId);
    }

    function purchaseTokens(uint256 listingId, uint256 amount) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing is not active");
        require(amount > 0 && amount <= listing.amount, "Invalid amount");

        uint256 totalPrice = listing.pricePerToken.mul(amount);
        require(msg.value >= totalPrice, "Insufficient payment");

        listing.amount = listing.amount.sub(amount);
        if (listing.amount == 0) {
            listing.active = false;
        }

        propertyToken.safeTransferFrom(address(this), msg.sender, listing.tokenId, amount, "");

        payable(listing.seller).transfer(totalPrice);

        // Refund excess payment
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }

        emit TokensPurchased(listingId, msg.sender, amount, totalPrice);
    }

    // Allow the contract to receive ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

