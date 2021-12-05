pragma solidity ^0.8.10;

/**
 * Rule 504 permits certain issuers to offer and sell up to $1 million of securities 
 * in any 12-month period.  These securities may be sold to any number and 
 * type of investor, and the issuer is not subject to specific disclosure requirements.  
 * Generally, securities issued under Rule 504 will be restricted securities 
 * (as further explained below), unless the offering meets certain additional requirements.
 * As a prospective investor, you should confirm with the issuer whether the securities 
 * being offered under this rule will be restricted.  
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Time.sol";

contract PrivateEquityToken504 is BasicToken, Time {
    string public symbol;
    string public name;

  constructor(string _symbol, string _name, uint _supply, string hash, address _registry,string calldata svgCode) {
    symbol = _symbol;
    name = _name;
    totalSupply_ = _supply;
  }
}
