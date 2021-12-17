// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Burnable
 *
 * @dev Standard ERC20 token
 */
contract Burnable is ERC20 {
  using SafeMath for uint;

  bytes32 constant private ZERO_BYTES = bytes32(0);
  address constant private ZERO_ADDRESS = address(0);

  mapping (address => uint256) public balances;
  mapping (address => uint256) private allowed;

  /* This notifies clients about the amount burnt */
  event Burn(address indexed from, uint value);

  function burn(uint _value) public returns (bool success) {
    require(_value > 0 && balances[msg.sender] >= _value, "");
    balances[msg.sender] = balances[msg.sender].sub(_value);
    //balances[totalSupply].sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint _value) public returns (bool success) {
    require(_from != ZERO_ADDRESS && _value > 0 && balances[_from] >= _value, "");
    //require(_value <= allowed[_from][msg.sender], "");
    balances[_from] = balances[_from].sub(_value);
    //totalSupply -= uint256(_value);
    //allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Burn(_from, _value);
    return true;
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    require(_to != ZERO_ADDRESS, ""); //use burn

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(_to != ZERO_ADDRESS, ""); //use burn

    return super.transferFrom(_from, _to, _value);
  }
}
