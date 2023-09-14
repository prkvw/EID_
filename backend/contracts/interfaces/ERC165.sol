// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract ERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165_INVALID = 0xffffffff;

    mapping(bytes4 => bool) internal _supportedInterfaces;

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(
        bytes4 interfaceID
    ) external view returns (bool) {
        return
            interfaceID != _INTERFACE_ID_ERC165_INVALID &&
            _supportedInterfaces[interfaceID];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(
            interfaceId != _INTERFACE_ID_ERC165_INVALID,
            "ERC165: invalid interface id"
        );
        _supportedInterfaces[interfaceId] = true;
    }
}
