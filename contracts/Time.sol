pragma solidity ^0.8.10;

// See https://programtheblockchain.com/posts/2018/01/12/writing-a-contract-that-handles-time/

contract Time {
  uint256 public createTime;

  constructor() {
    createTime = block.timestamp;
  }
}
