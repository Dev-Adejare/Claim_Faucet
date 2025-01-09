// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PropertyTokenERC1155.sol";
import "./PropertyTokenERC20.sol";

contract PropertyRegistry is Ownable {
    struct Property {
        string location;
        uint256 value;
        bool isVerified;
        address tokenAddress;
        bool isERC20;
    }

    mapping(uint256 => Property) public properties;
    mapping(string => bool) public registeredLocations;
    mapping(address => bool) public verifiedUsers;

    event PropertyRegistered(uint256 indexed propertyId, string location, uint256 value, address tokenAddress, bool isERC20);
    event PropertyVerified(uint256 indexed propertyId);
    event UserVerified(address indexed user);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function registerProperty(uint256 propertyId, string memory location, uint256 value, address tokenAddress, bool isERC20) public onlyOwner {
        require(!registeredLocations[location], "Property already registered");
        properties[propertyId] = Property(location, value, false, tokenAddress, isERC20);
        registeredLocations[location] = true;
        emit PropertyRegistered(propertyId, location, value, tokenAddress, isERC20);
    }

    function verifyProperty(uint256 propertyId) public onlyOwner {
        require(properties[propertyId].value != 0, "Property does not exist");
        properties[propertyId].isVerified = true;
        emit PropertyVerified(propertyId);
    }

    function verifyUser(address user) public onlyOwner {
        verifiedUsers[user] = true;
        emit UserVerified(user);
    }

    function getProperty(uint256 propertyId) public view returns (string memory location, uint256 value, bool isVerified, address tokenAddress, bool isERC20) {
        Property memory prop = properties[propertyId];
        return (prop.location, prop.value, prop.isVerified, prop.tokenAddress, prop.isERC20);
    }

    function isPropertyVerified(uint256 propertyId) public view returns (bool) {
        return properties[propertyId].isVerified;
    }

    function isUserVerified(address user) public view returns (bool) {
        return verifiedUsers[user];
    }

    function updatePropertyValue(uint256 propertyId, uint256 newValue) public onlyOwner {
        require(properties[propertyId].isVerified, "Property not verified");
        properties[propertyId].value = newValue;
        if (properties[propertyId].isERC20) {
            PropertyTokenERC20(properties[propertyId].tokenAddress).updatePropertyValue(newValue);
        } else {
            PropertyTokenERC1155(properties[propertyId].tokenAddress).updatePropertyValue(propertyId, newValue);
        }
    }
}

