// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RentalIncomeDistributor is ERC1155Holder, Ownable {
    using SafeMath for uint256;

    IERC1155 public propertyToken;
    mapping(uint256 => uint256) public rentalIncomeBalance;

    event RentalIncomeReceived(uint256 indexed tokenId, uint256 amount);
    event RentalIncomeDistributed(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    constructor(address _propertyTokenAddress) {
        propertyToken = IERC1155(_propertyTokenAddress);
    }

    function receiveRentalIncome(uint256 tokenId) public payable {
        require(msg.value > 0, "Must send some ETH");
        rentalIncomeBalance[tokenId] = rentalIncomeBalance[tokenId].add(msg.value);
        emit RentalIncomeReceived(tokenId, msg.value);
    }

    function distributeRentalIncome(uint256 tokenId) public {
        uint256 totalSupply = propertyToken.totalSupply(tokenId);
        require(totalSupply > 0, "No tokens minted for this property");

        uint256 totalIncome = rentalIncomeBalance[tokenId];
        require(totalIncome > 0, "No rental income to distribute");

        uint256 incomePerToken = totalIncome.div(totalSupply);

        address[] memory holders = getTokenHolders(tokenId);
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 balance = propertyToken.balanceOf(holder, tokenId);
            if (balance > 0) {
                uint256 holderIncome = incomePerToken.mul(balance);
                payable(holder).transfer(holderIncome);
                emit RentalIncomeDistributed(tokenId, holder, holderIncome);
            }
        }

        rentalIncomeBalance[tokenId] = 0;
    }

    // This function should be implemented to return all token holders
    // You might need to use events or an off-chain indexer to track all token holders efficiently
    function getTokenHolders(uint256 tokenId) internal view returns (address[] memory) {
        // Implementation depends on how you track token holders
        // This is a placeholder and needs to be properly implemented
    }

    // Allow the contract to receive ETH
    receive() external payable {}
}

