// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FinancialManager is Ownable {
    using SafeMath for uint256;

    struct PropertyFinancials {
        uint256 totalRentalIncome;
        uint256 rentalIncomePerShare;
        uint256 lastRentalUpdate;
        uint256 lastDistributionTimestamp;
        bool isActive;
        uint256 totalExpenses;
        uint256[] monthlyRentalIncome;
        uint256 totalShares;
        uint256 currentValuation;
    }

    mapping(uint256 => PropertyFinancials) private _propertyFinancials;
    mapping(uint256 => mapping(address => uint256)) private _unclaimedRentalIncome;

    // Add this new mapping to track token balances

    mapping(uint256 => mapping(address => uint256)) private _tokenBalances;

    event RentalIncomeUpdated(uint256 indexed propertyId, uint256 totalRentalIncome);
    event RentalIncomeDistributed(uint256 indexed propertyId, uint256 totalAmount);
    event ExpenseRecorded(uint256 indexed propertyId, uint256 amount, string description);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    constructor() Ownable(msg.sender) {}

    function initializePropertyFinancials(uint256 propertyId, uint256 totalShares, uint256 initialValuation) public onlyOwner {
        _propertyFinancials[propertyId] = PropertyFinancials({
            totalRentalIncome: 0,
            rentalIncomePerShare: 0,
            lastRentalUpdate: block.timestamp,
            lastDistributionTimestamp: block.timestamp,
            isActive: true,
            totalExpenses: 0,
            monthlyRentalIncome: new uint256[](0),
            totalShares: totalShares,
            currentValuation: initialValuation
        });
    }

    
    function updateRentalIncome(uint256 propertyId, uint256 newRentalIncome) public onlyOwner {
        PropertyFinancials storage financials = _propertyFinancials[propertyId];
        require(financials.isActive, "Property is not active");

        uint256 rentalIncrease = newRentalIncome.sub(financials.totalRentalIncome);
        financials.totalRentalIncome = newRentalIncome;

        uint256 increasePerShare = rentalIncrease.mul(1e18).div(financials.totalShares);
        financials.rentalIncomePerShare = financials.rentalIncomePerShare.add(increasePerShare);

        financials.lastRentalUpdate = block.timestamp;
        financials.monthlyRentalIncome.push(newRentalIncome);

        emit RentalIncomeUpdated(propertyId, newRentalIncome);
    }

    
    function distributeRentalIncome(uint256 propertyId) public {
        PropertyFinancials storage financials = _propertyFinancials[propertyId];
        require(financials.isActive, "Property is not active");

        uint256 totalDistribution = financials.totalRentalIncome.sub(
            financials.rentalIncomePerShare.mul(financials.totalShares).div(1e18)
        );
        if (totalDistribution > 0) {
            financials.rentalIncomePerShare = financials.rentalIncomePerShare.add(
                totalDistribution.mul(1e18).div(financials.totalShares)
            );

            financials.lastDistributionTimestamp = block.timestamp;

            emit RentalIncomeDistributed(propertyId, totalDistribution);
        }
    }

    
    function updateUnclaimedRentalIncome(uint256 propertyId, address user, uint256 amount) public onlyOwner {
        PropertyFinancials storage financials = _propertyFinancials[propertyId];
        _unclaimedRentalIncome[propertyId][user] = _unclaimedRentalIncome[propertyId][user].add(
            amount.mul(financials.rentalIncomePerShare).div(1e18)
        );
    }

    
    function claimRentalIncome(uint256 propertyId, address user) public onlyOwner returns (uint256) {
        PropertyFinancials storage financials = _propertyFinancials[propertyId];
        uint256 totalIncome = balanceOf(user, propertyId).mul(financials.rentalIncomePerShare).div(1e18);
        uint256 unclaimedIncome = totalIncome.sub(_unclaimedRentalIncome[propertyId][user]);

        require(unclaimedIncome > 0, "No rental income to claim");

        _unclaimedRentalIncome[propertyId][user] = totalIncome;
        return unclaimedIncome;
    }

    function getUnclaimedRentalIncome(uint256 propertyId, address user) public view returns (uint256) {
        PropertyFinancials storage financials = _propertyFinancials[propertyId];
        uint256 totalIncome = balanceOf(user, propertyId).mul(financials.rentalIncomePerShare).div(1e18);
        return totalIncome.sub(_unclaimedRentalIncome[propertyId][user]);
    }

    
    function recordExpense(uint256 propertyId, uint256 amount, string memory description) public onlyOwner {
        PropertyFinancials storage financials = _propertyFinancials[propertyId];
        require(financials.isActive, "Property is not active");

        financials.totalExpenses = financials.totalExpenses.add(amount);
        emit ExpenseRecorded(propertyId, amount, description);
    }

    function getFinancialReport(uint256 propertyId) public view returns (
        uint256 totalRentalIncome,
        uint256 totalExpenses,
        uint256 netIncome,
        uint256 currentValuation
    ) {
        PropertyFinancials storage financials = _propertyFinancials[propertyId];
        return (
            financials.totalRentalIncome,
            financials.totalExpenses,
            financials.totalRentalIncome.sub(financials.totalExpenses),
            financials.currentValuation
        );
    }

    // Add this new function to update token balances
    function updateTokenBalance(uint256 propertyId, address account, uint256 amount, bool isIncrease) public onlyOwner {
        if (isIncrease) {
            _tokenBalances[propertyId][account] = _tokenBalances[propertyId][account].add(amount);
        } else {
            require(_tokenBalances[propertyId][account] >= amount, "Insufficient balance");
            _tokenBalances[propertyId][account] = _tokenBalances[propertyId][account].sub(amount);
        }
    }

    // Update the balanceOf function
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        return _tokenBalances[id][account];
    }

    function updateCurrentValuation(uint256 propertyId, uint256 newValuation) public onlyOwner {
        require(_propertyFinancials[propertyId].isActive, "Property is not active");
        _propertyFinancials[propertyId].currentValuation = newValuation;
        emit ValuationUpdated(propertyId, newValuation);
    }
}

