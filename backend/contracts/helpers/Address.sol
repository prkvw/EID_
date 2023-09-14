// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Address {
    function isValid(address account) internal pure returns (bool) {
        return account != address(0);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function toPayable(
        address account
    ) internal pure returns (address payable) {
        return payable(account);
    }
}
