// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;




Contract Market is ERC 165, ERC 1155 { 

 // token owner => operator => approved true
    mapping(address => mapping(address => bool)) private operators;
    // token owner => token id => balance
    mapping(address => mapping(uint256 => uint256)) private balances;

    //creators
    //owners

    modifier onlyAdmin() {
        require(
            msg.sender == administrator,
            "ERC1155: caller is not the administrator"
        );
    event Minted(
        address indexed _owner,
        uint256 indexed  pricePerToken,
        uint256 indexed _tokenId
    );

    event AssetTransfer ( 
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    );

    Struct Assets { 
    string title
    string description
   string  location
   uint     _itemId
   uint256  pricePerToken
    address owner
    bool    isShared
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
        emit AssetTransfer(msg.sender, _from, _to, _id, _value);
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

//
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


// function mint 
function mint(address _to) external onlyAdmin {
        uint256 id = tokenStore.mint(_to, "");
        balances[_to] += 1;
        emit Transfer(address(0), _to, id);
    }

//require bool is true ()

// function transfer : assign {address, address}

//  managing functions 
function approve(address _approved, uint256 _tokenId) external payable;

    //burn

    // update

// function buyAsset (uint _itemId, uint _numOfToken) external payable {}

//
function isApprovedForAll(
        address _owner,
        address _operator
    ) external view override returns (bool) {
        return operators[_owner][_operator];
    }

}