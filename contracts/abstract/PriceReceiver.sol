// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.5.11;

contract PriceReceiver {
  address public ethPriceProvider;

  address public btcPriceProvider;

  modifier onlyEthPriceProvider() {
    require(msg.sender == ethPriceProvider, "");
    _;
  }

  modifier onlyBtcPriceProvider() {
    require(msg.sender == btcPriceProvider, "");
    _;
  }

  function receiveEthPrice(uint ethUsdPrice) external;

  function receiveBtcPrice(uint btcUsdPrice) external;

  function setEthPriceProvider(address provider) external;

  function setBtcPriceProvider(address provider) external;
}