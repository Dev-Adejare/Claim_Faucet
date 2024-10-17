// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

interface IERC20 {
  
    function getTokenName() external view returns (string memory);

    function getSymbol() external view returns (string memory);

    function claimToken(address _address) external ; 

    function balanceOf(address _address) external view returns (uint256);

}
