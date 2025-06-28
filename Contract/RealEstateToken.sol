// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PropertyManager.sol";
import "./FinancialManager.sol";
import "./KYCManager.sol";


contract RealEstateToken is ERC1155, Ownable {
    using SafeMath for uint256;

    PropertyManager public propertyManager;
    FinancialManager public financialManager;
    KYCManager public kycManager;

    uint256 public constant PLATFORM_FEE_PERCENTAGE = 2;

    event TokenSharesPurchased(
        uint256 indexed propertyId,
        address indexed buyer,
        uint256 amount,
        uint256 totalPrice
    );

    event RentalIncomeClaimed(
        address indexed account,
        uint256 indexed propertyId,
        uint256 amount
    );

    event SharesLiquidated(
        uint256 indexed propertyId,
        address indexed seller,
        uint256 amount,
        uint256 totalPrice
    );

     constructor(
        address _propertyManager,
        address _financialManager,
        address _kycManager
    ) ERC1155("https://api.example.com/token/{id}.json") Ownable(msg.sender) {
        propertyManager = PropertyManager(_propertyManager);
        financialManager = FinancialManager(_financialManager);
        kycManager = KYCManager(_kycManager);
    }

    function tokenizeProperty(
        string memory name,
        string memory location,
        string memory description,
        string[] memory imageUrls,
        uint256 totalShares,
        uint256 pricePerShare,
        uint256 initialValuation
    ) public {
        require(
            kycManager.isUserVerified(msg.sender),
            "User must be KYC verified to tokenize property"
        );
        uint256 newPropertyId = propertyManager.createProperty(
            name,
            location,
            description,
            imageUrls,
            totalShares,
            pricePerShare,
            initialValuation
        );
        _mint(msg.sender, newPropertyId, totalShares, "");
        financialManager.initializePropertyFinancials(newPropertyId, totalShares, initialValuation);
        financialManager.updateTokenBalance(newPropertyId, msg.sender, totalShares, true);
    }

    function buyTokenShares(uint256 propertyId, uint256 amount) public payable {
        require(
            kycManager.isUserVerified(msg.sender),
            "User must be KYC verified to enable buy shares"
        );
        (uint256 totalPrice, uint256 availableShares) = propertyManager.calculatePurchase(propertyId, amount);
        require(msg.value >= totalPrice, "Insufficient funds sent");
        require(availableShares >= amount, "Not enough shares available");

        financialManager.distributeRentalIncome(propertyId);
        safeTransferFrom(address(this), msg.sender, propertyId, amount, "");
        propertyManager.updateAvailableShares(propertyId, amount);
        financialManager.updateUnclaimedRentalIncome(propertyId, msg.sender, amount);

        payable(owner()).transfer(totalPrice);
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }

        emit TokenSharesPurchased(propertyId, msg.sender, amount, totalPrice);
    }


    function claimRentalIncome(uint256 propertyId) public {
        require(balanceOf(msg.sender, propertyId) > 0, "User does not own shares of this property");
        financialManager.distributeRentalIncome(propertyId);
        uint256 unclaimedIncome = financialManager.claimRentalIncome(propertyId, msg.sender);
        payable(msg.sender).transfer(unclaimedIncome);
        emit RentalIncomeClaimed(msg.sender, propertyId, unclaimedIncome);
    }
    
    function liquidateShares(uint256 propertyId, uint256 amount) public {
        require(balanceOf(msg.sender, propertyId) >= amount, "Insufficient shares to liquidate");
        uint256 totalPrice = propertyManager.calculateLiquidationPrice(propertyId, amount);
        safeTransferFrom(msg.sender, address(this), propertyId, amount, "");
        propertyManager.updateAvailableShares(propertyId, amount);
        payable(msg.sender).transfer(totalPrice);
        emit SharesLiquidated(propertyId, msg.sender, amount, totalPrice);
    }

    function getUnclaimedRentalIncome(uint256 propertyId, address user) public view returns (uint256) {
        return financialManager.getUnclaimedRentalIncome(propertyId, user);
    }

    function getPropertyInfo(uint256 propertyId) public view returns (
        string memory name,
        string memory location,
        uint256 totalShares,
        uint256 pricePerShare,
        bool isForSale,
        uint256 salePrice
    ) {
        return propertyManager.getPropertyInfo(propertyId);
    }

    function getFinancialReport(uint256 propertyId) public view returns (
        uint256 totalRentalIncome,
        uint256 totalExpenses,
        uint256 netIncome,
        uint256 currentValuation
    ) {
        return financialManager.getFinancialReport(propertyId);
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        return financialManager.balanceOf(account, id);
    }
}

