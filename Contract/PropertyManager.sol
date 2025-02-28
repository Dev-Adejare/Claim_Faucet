// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract PropertyManager is Ownable {
    using SafeMath for uint256;

    struct PropertyInfo {
        string name;
        string location;
        string description;
        string[] imageUrls;
        uint256 totalShares;
        uint256 pricePerShare;
        uint256 initialValuation;
        uint256 currentValuation;
        uint256 creationTimestamp;
        bool isForSale;
        uint256 salePrice;
    }
    
    mapping(uint256 => PropertyInfo) private _propertyInfo;
    mapping(uint256 => uint256) private _availableShares;
    uint256 private _nextPropertyId = 1;

    event PropertyTokenized(
        uint256 indexed propertyId,
        string name,
        string location,
        uint256 totalShares,
        uint256 pricePerShare,
        uint256 initialValuation
    );

    constructor() Ownable(msg.sender) {}

    function createProperty(
        string memory name,
        string memory location,
        string memory description,
        string[] memory imageUrls,
        uint256 totalShares,
        uint256 pricePerShare,
        uint256 initialValuation
    ) public onlyOwner returns (uint256) {
        uint256 newPropertyId = _nextPropertyId;

        _propertyInfo[newPropertyId] = PropertyInfo({
            name: name,
            location: location,
            description: description,
            imageUrls: imageUrls,
            totalShares: totalShares,
            pricePerShare: pricePerShare,
            initialValuation: initialValuation,
            currentValuation: initialValuation,
            creationTimestamp: block.timestamp,
            isForSale: false,
            salePrice: 0
        });

        _availableShares[newPropertyId] = totalShares;

        emit PropertyTokenized(
            newPropertyId,
            name,
            location,
            totalShares,
            pricePerShare,
            initialValuation
        );

        _nextPropertyId++;
        return newPropertyId;
    }

    function calculatePurchase(uint256 propertyId, uint256 amount) public view returns (uint256, uint256) {
        PropertyInfo storage propertyInfo = _propertyInfo[propertyId];
        uint256 totalPrice = amount.mul(propertyInfo.pricePerShare);
        return (totalPrice, _availableShares[propertyId]);
    }

    function updateAvailableShares(uint256 propertyId, uint256 amount) public onlyOwner {
        _availableShares[propertyId] = _availableShares[propertyId].sub(amount);
    }

    function calculateLiquidationPrice(uint256 propertyId, uint256 amount) public view returns (uint256) {
        PropertyInfo storage property = _propertyInfo[propertyId];
        return amount.mul(property.currentValuation).div(property.totalShares);
    }

    function getPropertyInfo(uint256 propertyId) public view returns (
        string memory name,
        string memory location,
        uint256 totalShares,
        uint256 pricePerShare,
        bool isForSale,
        uint256 salePrice
    ) {
        PropertyInfo storage property = _propertyInfo[propertyId];
        return (
            property.name,
            property.location,
            property.totalShares,
            property.pricePerShare,
            property.isForSale,
            property.salePrice
        );
    }

    function updatePropertyValuation(uint256 propertyId, uint256 newValuation) public onlyOwner {
        _propertyInfo[propertyId].currentValuation = newValuation;
    }
}

