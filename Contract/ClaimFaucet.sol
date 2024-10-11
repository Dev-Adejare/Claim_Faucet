// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./DltToken.sol";

contract ClaimFaucet is DltToken{
    
    uint256 public constant CLAIMABLE_AMOUNT = 10 * (10**18);

    constructor(string memory _name, string memory _symbol) DltToken(_name, _symbol){}

    struct User{
        uint256 lastClaimTime;
        uint256 totalClaimed;
    }

    mapping (address => User) users;

    mapping (address => bool) hasClaimedBefore;
    

    function claimToken() public {
        require(msg.sender != address(0), "Zero address not allowe");

        if(hasClaimedBefore[msg.sender]){

        }else{
            hasClaimedBefore[msg.sender] = true;
            mint(CLAIMABLE_AMOUNT, msg.sender);

            User memory currentUser;
            currentUser.lastClaimTime = block.timestamp;
            currentUser.totalClaimed = CLAIMABLE_AMOUNT;
        }
    }


}