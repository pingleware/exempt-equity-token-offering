// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.22 <0.9.0;

contract Owned {
  address owner;

  constructor() public {
  }

  modifier onlyowner() {
    if (msg.sender == owner) {
      _;
    }
  }

  function owned() public {
    owner = msg.sender;
  }

}
