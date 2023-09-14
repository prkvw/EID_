// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ERC165.sol";
import "./interfaces/ERC1155.sol";
import "./interfaces/ERC1155TokenReceiver.sol";
import "./helpers/Address.sol";
import "./helpers/Counter.sol";
import "./helpers/SafeMath.sol";
import "./helpers/Tokens.sol";

contract Vault is ERC165, ERC1155 {
    using Address for address;
    using Counter for Counter.Value;
    using Tokens for Tokens.TokenStorage;
    using SafeMath for uint256;

    bytes4 public constant ERC1155_ERC165 = 0xd9b67a26;
    bytes4 public constant ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 public constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;

    address private administrator;
    Tokens.TokenStorage private tokenStore;

    // token owner => operator => approved
    mapping(address => mapping(address => bool)) private operators;
    // token owner => token id => balance
    mapping(address => mapping(uint256 => uint256)) private balances;

    modifier onlyAdmin() {
        require(
            msg.sender == administrator,
            "ERC1155: caller is not the administrator"
        );
        _;
    }
    modifier onlyOwnerOrOperator(address _owner) {
        require(
            _owner == msg.sender || operators[_owner][msg.sender],
            "ERC1155: caller is not owner or approved operator"
        );
        _;
    }
    modifier whenNotZeroAddress(address _address) {
        require(_address != address(0), "ERC1155: zero address");
        _;
    }

    constructor() {
        _registerInterface(ERC1155_ERC165);
        administrator = msg.sender;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) private {
        balances[_from][_id] = balances[_from][_id].sub(_value);
        balances[_to][_id] = balances[_to][_id].add(_value);
    }

    function mint(
        address _to,
        string memory _uri,
        uint256 _value
    ) external onlyAdmin whenNotZeroAddress(_to) {
        require(_value > 0, "ERC1155: mint amount must be greater than zero");
        uint256 id = tokenStore.mint(_to, _uri);
        balances[_to][id] = balances[_to][id].add(_value);
        emit TransferSingle(address(0), msg.sender, _to, id, _value);
    }

    function balanceOf(
        address _owner,
        uint256 _id
    ) external view override returns (uint256) {
        require(
            _owner.isValid(),
            "ERC1155: balance query for the zero address"
        );
        return balances[_owner][_id];
    }

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) external view override returns (uint256[] memory) {
        require(
            _owners.length == _ids.length,
            "ERC1155: owners and ids length mismatch"
        );
        uint256[] memory _balances = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            require(
                _owners[i].isValid(),
                "ERC1155: balance query for the zero address"
            );
            _balances[i] = balances[_owners[i]][_ids[i]];
        }
        return _balances;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override onlyOwnerOrOperator(_from) {
        require(_to.isValid(), "ERC1155: transfer to the zero address");
        require(
            _value > 0,
            "ERC1155: transfer amount must be greater than zero"
        );
        require(
            balances[_from][_id] >= _value,
            "ERC1155: insufficient balance for transfer"
        );
        _transfer(_from, _to, _id, _value);
        if (_to.code.length != 0) {
            bytes4 _receiverInterfaceId = ERC1155TokenReceiver(_to)
                .onERC1155Received(msg.sender, _from, _id, _value, _data);
            require(
                _receiverInterfaceId == ERC1155_ACCEPTED,
                "ERC1155: transfer rejected by receiver"
            );
        }
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override {
        require(
            _from == msg.sender || operators[_from][msg.sender],
            "ERC1155: transfer caller is not owner or approved operator"
        );
        require(_to.isValid(), "ERC1155: transfer to the zero address");
        require(
            _ids.length == _values.length,
            "ERC1155: ids and values length mismatch"
        );
        require(
            _ids.length > 0,
            "ERC1155: ids and values length must be greater than zero"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                balances[_from][_ids[i]] >= _values[i],
                "ERC1155: insufficient balance for transfer"
            );
            _transfer(_from, _to, _ids[i], _values[i]);
        }

        if (_to.isContract()) {
            bytes4 retval = ERC1155TokenReceiver(_to).onERC1155BatchReceived(
                msg.sender,
                _from,
                _ids,
                _values,
                _data
            );
            require(
                retval == ERC1155_BATCH_ACCEPTED,
                "ERC1155: transfer rejected by receiver"
            );
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) external override {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view override returns (bool) {
        return operators[_owner][_operator];
    }
}
