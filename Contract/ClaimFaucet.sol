// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./DltToken.sol";

contract ClaimFaucet is DltToken{

    uint256 public constant CLAIMABLE_AMOUNT = 10;

    constructor(string memory _name, string memory _symbol) DltToken(_name, _symbol){}

    struct User{
        uint256 lastClaimTime;
        uint256 totalClaimed;
    }

    mapping (address => User) users;

    mapping (address => bool) hasClaimedBefore;

    event TokenClaimSuccessful(address indexed user, uint256 _amount, uint256 _time);


    function claimToken(address _address) public {
        require(_address != address(0), "Zero address not allowed");

        if(hasClaimedBefore[_address]){

            User storage currentUser = users[_address];
            require(block.timestamp > (currentUser.lastClaimTime + 1 days), "You claim once after 24 hours");

            currentUser.lastClaimTime = block.timestamp;
            
            currentUser.totalClaimed += CLAIMABLE_AMOUNT;

            mint(CLAIMABLE_AMOUNT, _address);

            emit TokenClaimSuccessful(_address, CLAIMABLE_AMOUNT, block.timestamp);

        }else{
            hasClaimedBefore[_address] = true;
            mint(CLAIMABLE_AMOUNT, _address);

            User memory currentUser;
            currentUser.lastClaimTime = block.timestamp;
            currentUser.totalClaimed = CLAIMABLE_AMOUNT;

            users[_address] = currentUser;

            emit TokenClaimSuccessful(_address, CLAIMABLE_AMOUNT, block.timestamp);
        }
    }

   


}