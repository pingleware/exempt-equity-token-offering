// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.5.11;

// See https://programtheblockchain.com/posts/2018/01/12/writing-a-contract-that-handles-time/

contract Time {
  uint256 public createTime;
  uint256 public currentTime;

  constructor() public {
    createTime = now;
    currentTime = now;
  }
}
