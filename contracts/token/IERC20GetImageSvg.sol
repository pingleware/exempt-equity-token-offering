// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.5.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IERC20GetImageSvg is IERC20 {
  function getTokenImageSvg() external view returns (string memory);
  function getForm144ImageSvg() external view returns (string memory);
}
