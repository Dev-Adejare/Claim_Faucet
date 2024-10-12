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


    function claimToken() public {
        require(msg.sender != address(0), "Zero address not allowed");

        if(hasClaimedBefore[msg.sender]){

            User storage currentUser = users[msg.sender];
            require(block.timestamp > (currentUser.lastClaimTime + 1 days), "You claim once after 24 hours");

            currentUser.lastClaimTime = block.timestamp;
            
            currentUser.totalClaimed += CLAIMABLE_AMOUNT;

            mint(CLAIMABLE_AMOUNT, msg.sender);

            emit TokenClaimSuccessful(msg.sender, CLAIMABLE_AMOUNT, block.timestamp);

        }else{
            hasClaimedBefore[msg.sender] = true;
            mint(CLAIMABLE_AMOUNT, msg.sender);

            User memory currentUser;
            currentUser.lastClaimTime = block.timestamp;
            currentUser.totalClaimed = CLAIMABLE_AMOUNT;

            users[msg.sender] = currentUser;

            emit TokenClaimSuccessful(msg.sender, CLAIMABLE_AMOUNT, block.timestamp);
        }
    }

    function getUserData() external view returns (uint256, uint256){
        User memory currentUser = users[msg.sender];

        return (currentUser.lastClaimTime, currentUser.totalClaimed);
    }


}