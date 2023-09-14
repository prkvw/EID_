// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ERC165.sol";
import "./interfaces/ERC721.sol";
import "./interfaces/ERC721Metadata.sol";
import "./interfaces/ERC721TokenReceiver.sol";
import "./interfaces/ERC721Enumerable.sol";
import "./helpers/Address.sol";
import "./helpers/Counter.sol";
import "./helpers/SafeMath.sol";
import "./helpers/Tokens.sol";

contract W3BToken is ERC165, ERC721, ERC721Metadata, ERC721Enumerable {
    using Address for address;
    using SafeMath for uint256;
    using Tokens for Tokens.TokenStorage;

    bytes4 private constant ERC721_ERC165 = 0x80ac58cd;
    bytes4 private constant ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant ERC721_ACCEPTED = 0x150b7a02;

    address private administrator;
    Tokens.TokenStorage private tokenStore;
    mapping(address => uint) private balances;
    mapping(address => mapping(address => bool)) private operators;

    modifier authorized(uint256 _tokenId) {
        require(
            tokenStore.tokens[_tokenId].owner == msg.sender ||
                tokenStore.tokens[_tokenId].approved == msg.sender ||
                operators[tokenStore.tokens[_tokenId].owner][msg.sender],
            "ERC721: transfer caller is not owner nor approved"
        );
        _;
    }
    modifier validToken(uint256 _tokenId) {
        require(tokenStore.exists(_tokenId), "ERC721: invalid token");
        _;
    }
    modifier notToZeroAddress(address to) {
        require(to != address(0), "ERC721: transfer to the zero address");
        _;
    }
    modifier fromOwner(uint256 _tokenId, address _from) {
        require(
            tokenStore.tokens[_tokenId].owner == _from,
            "ERC721: transfer of token that is not owned"
        );
        _;
    }
    modifier onlyAdmin() {
        require(
            msg.sender == administrator,
            "W3B Token: caller is not the administrator"
        );
        _;
    }

    constructor() {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(ERC721_ERC165);
        _registerInterface(ERC721_METADATA);
        _registerInterface(ERC721_ENUMERABLE);
        administrator = msg.sender;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        balances[_from] = balances[_from].sub(1);
        balances[_to] = balances[_to].add(1);
        tokenStore.transfer(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function mint(address _to) external onlyAdmin {
        uint256 id = tokenStore.mint(_to, "");
        balances[_to] += 1;
        emit Transfer(address(0), _to, id);
    }

    function balanceOf(
        address _owner
    ) external view override returns (uint256) {
        require(_owner.isValid(), "ERC721: balance query for the zero address");
        return balances[_owner];
    }

    function ownerOf(
        uint256 _tokenId
    ) external view override validToken(_tokenId) returns (address) {
        return tokenStore.ownerOf(_tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    )
        public
        payable
        override
        validToken(_tokenId)
        authorized(_tokenId)
        notToZeroAddress(_to)
        fromOwner(_tokenId, _from)
    {
        _transfer(_from, _to, _tokenId);
        require(
            checkERC721Support(_from, _to, _tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
        safeTransferFrom(_from, _to, _tokenId, bytes(""));
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        payable
        override
        validToken(_tokenId)
        authorized(_tokenId)
        fromOwner(_tokenId, _from)
        notToZeroAddress(_to)
    {
        _transfer(_from, _to, _tokenId);
    }

    function approve(
        address _approved,
        uint256 _tokenId
    ) external payable override {
        address owner = tokenStore.ownerOf(_tokenId);
        require(
            owner == msg.sender || operators[owner][msg.sender],
            "ERC721: approve caller is not owner nor approved for all"
        );
        tokenStore.approve(_approved, _tokenId);
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) external override {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(
        uint256 _tokenId
    ) external view override validToken(_tokenId) returns (address) {
        return tokenStore.getApproved(_tokenId);
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view override returns (bool) {
        return operators[_owner][_operator];
    }

    function name() external pure override returns (string memory _name) {
        return "W3B Token";
    }

    function symbol() external pure override returns (string memory _symbol) {
        return "W3B";
    }

    function tokenURI(
        uint256 _tokenId
    ) external view override returns (string memory) {
        return tokenStore.tokenURI(_tokenId);
    }

    function totalSupply() external view override returns (uint256) {
        return tokenStore.totalSupply();
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) external view override returns (uint256) {
        require(
            _index < balances[_owner],
            "ERC721Enumerable: owner index out of bounds"
        );
        return balances[_owner];
    }

    function tokenByIndex(
        uint256 _index
    ) external view override returns (uint256) {
        return tokenStore.tokenByIndex(_index);
    }

    function checkERC721Support(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 returnData = ERC721TokenReceiver(_to).onERC721Received(
            msg.sender,
            _from,
            _tokenId,
            _data
        );
        return returnData == ERC721_ACCEPTED;
    }
}
