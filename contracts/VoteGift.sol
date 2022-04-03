// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * 选举纪念NFT,参与投票的地址有资格mint
 */
contract VoteGift is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    //mapping owner address to tokenId , when the value is 0, that means the address owns no one
    mapping (address => uint256) public ownWhichOne;

    constructor() ERC721("VoteGift", "VGC") {}

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        //the beginning tokenId is set 1
        if(tokenId == 0){
            tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
        }

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        ownWhichOne[to] = tokenId;
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}