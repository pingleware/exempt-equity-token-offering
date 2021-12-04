pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IERC20GetImageSvg is IERC20 {
  function getTokenImageSvg() external view returns (string memory);
  function getForm144ImageSvg() external view returns (string memory);
}
