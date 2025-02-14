// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KYCManager is Ownable {
    struct KYC {
        string name;
        string email;
        string nationality;
        string idNumber;
        string idImage;
        bool isVerified;
    }

    mapping(address => KYC) private _userKYC;

    event KYCSubmitted(address indexed user, string name, string nationality);
    event KYCVerified(address indexed user, bool isVerified);

    constructor() Ownable(msg.sender) {}

    function submitKYC(
        string memory name,
        string memory email,
        string memory nationality,
        string memory idNumber,
        string memory idImage
    ) public {
        require(bytes(name).length > 0, "Name is required");
        require(bytes(email).length > 0, "Email is required");
        require(bytes(nationality).length > 0, "Nationality is required");
        require(bytes(idNumber).length > 0, "ID Number is required");
        require(bytes(idImage).length > 0, "ID Image is required");

        _userKYC[msg.sender] = KYC({
            name: name,
            email: email,
            nationality: nationality,
            idNumber: idNumber,
            idImage: idImage,
            isVerified: false
        });

        emit KYCSubmitted(msg.sender, name, nationality);
    }

    function verifyKYC(address user, bool status) public onlyOwner {
        require(
            bytes(_userKYC[user].name).length > 0,
            "User has not submitted KYC"
        );

        _userKYC[user].isVerified = status;

        emit KYCVerified(user, status);
    }

    function isUserVerified(address user) public view returns (bool) {
        return _userKYC[user].isVerified;
    }
}
