// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Address.sol";

library Tokens {
    using SafeMath for uint256;
    using Address for address;

    struct Token {
        uint256 id;
        address owner;
        address approved;
        string uri;
    }

    struct TokenStorage {
        uint256 tokenId;
        mapping(uint256 => Token) tokens;
    }

    function mint(
        TokenStorage storage tokenStore,
        address _to,
        string memory _uri
    ) internal returns (uint256) {
        require(_to != address(0), "Mint to the zero address");
        tokenStore.tokenId = tokenStore.tokenId.add(1);
        uint256 newTokenId = tokenStore.tokenId;
        tokenStore.tokens[newTokenId] = Token({
            id: newTokenId,
            owner: _to,
            approved: address(0),
            uri: _uri
        });
        return newTokenId;
    }

    function burn(
        TokenStorage storage tokenStore,
        uint256 _tokenId,
        address _owner
    ) internal {
        require(
            tokenStore.tokens[_tokenId].owner == _owner,
            "ERC721: burn of token that is not own"
        );
        delete tokenStore.tokens[_tokenId];
    }

    function transfer(
        TokenStorage storage tokenStore,
        address _to,
        uint256 _tokenId
    ) internal {
        tokenStore.tokens[_tokenId].owner = _to;
        tokenStore.tokens[_tokenId].approved = address(0);
    }

    function approve(
        TokenStorage storage tokenStore,
        address _approved,
        uint256 _tokenId
    ) internal {
        tokenStore.tokens[_tokenId].approved = _approved;
    }

    function getApproved(
        TokenStorage storage tokenStore,
        uint256 _tokenId
    ) internal view returns (address) {
        return tokenStore.tokens[_tokenId].approved;
    }

    function exists(
        TokenStorage storage tokenStore,
        uint256 _tokenId
    ) internal view returns (bool) {
        return tokenStore.tokens[_tokenId].owner != address(0);
    }

    function ownerOf(
        TokenStorage storage tokenStore,
        uint256 _tokenId
    ) internal view returns (address) {
        return tokenStore.tokens[_tokenId].owner;
    }

    function tokenURI(
        TokenStorage storage tokenStore,
        uint256 _tokenId
    ) internal view returns (string memory) {
        return tokenStore.tokens[_tokenId].uri;
    }

    function totalSupply(
        TokenStorage storage tokenStore
    ) internal view returns (uint256) {
        uint256 counter = 0;
        for (uint256 i = 0; i < tokenStore.tokenId; i++) {
            if (tokenStore.tokens[i + 1].owner != address(0)) {
                counter += 1;
            }
        }
        return counter;
    }

    function tokensByOwner(
        TokenStorage storage tokenStore,
        address _owner
    ) internal view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](tokenStore.tokenId);
        uint256 counter = 0;
        for (uint256 i = 0; i < tokenStore.tokenId; i++) {
            if (tokenStore.tokens[i + 1].owner == _owner) {
                tokens[counter] = i + 1;
                counter += 1;
            }
        }
        return tokens;
    }

    function tokenOfOwnerByIndex(
        TokenStorage storage tokenStore,
        address _owner,
        uint256 _index
    ) internal view returns (uint256) {
        uint256[] memory tokens = tokensByOwner(tokenStore, _owner);
        require(_index < tokens.length, "Invalid index");
        return tokens[_index];
    }

    function tokenByIndex(
        TokenStorage storage tokenStore,
        uint256 _index
    ) internal view returns (uint256) {
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < tokenStore.tokenId; i++) {
            if (tokenStore.tokens[i + 1].owner != address(0)) {
                if (currentIndex == _index) {
                    return i + 1;
                }
                currentIndex += 1;
            }
        }
        revert("Invalid index");
    }
}
