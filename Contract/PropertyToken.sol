// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract PropertyToken is ERC1155, Ownable, ERC1155Supply {
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) public propertyManagers;

    event PropertyTokenized(uint256 indexed tokenId, string propertyDetails, uint256 totalSupply);

    constructor() ERC1155("") {}

    function setURI(uint256 tokenId, string memory newuri) public onlyOwner {
        _tokenURIs[tokenId] = newuri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function tokenizeProperty(
        uint256 tokenId,
        uint256 initialSupply,
        string memory propertyDetails,
        string memory tokenURI,
        address propertyManager
    ) public onlyOwner {
        require(totalSupply(tokenId) == 0, "Property already tokenized");
        _mint(msg.sender, tokenId, initialSupply, "");
        setURI(tokenId, tokenURI);
        propertyManagers[tokenId] = propertyManager;
        emit PropertyTokenized(tokenId, propertyDetails, initialSupply);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

