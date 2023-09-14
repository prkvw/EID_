// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Counter {
    struct Value {
        uint256 value;
    }

    function next(Value storage self) external returns (uint256) {
        self.value += 1;
        return self.value;
    }

    function current(Value storage self) external view returns (uint256) {
        return self.value;
    }
}
