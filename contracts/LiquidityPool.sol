// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// Implementation of a Constant Product Automated Market Maker

// Other liquidiuty pool contracts: https://github.com/search?p=2&q=liquidity+pool+contract&type=Repositories
// https://github.com/OCTIONOFFICIAL/liquiditypoolV2

contract LiquidityPool {

  uint private k = 2500000000;
  uint public equityToken501c = 500000;
  uint public investorCash = 500000;

  uint public parValue = 10;

  address private owner;

  uint constant private fee_pct = 1;
  uint private total_fees = 0;

  struct Transaction {
    uint256 time;
    address sender;
    uint amount;
    uint fee;
  }

  mapping(uint => Transaction[]) private transactions;

  struct Investor {
    address addr;
    uint256 time;
    uint amount;
  }

  mapping(address => Investor[]) private investors;

  constructor(uint tokens, uint cash, uint _parValue) public {
    owner = msg.sender;
    parValue = _parValue;
    equityToken501c = tokens;
    investorCash = cash;
    k = tokens * cash;
    Investor memory investor = Investor(owner, now, cash);
    investors[owner].push(investor);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "access denied");
    _;
  }

  /**
   * Owner can add investor cash and tokens to the liquidity pool
   */
  function add(uint tokens, uint cash) public payable onlyOwner {
    require((equityToken501c + tokens) * (investorCash + cash) == k,"liquidity pool is out of balance");
    equityToken501c += tokens;
    investorCash += cash;
  }

  function invest(address invaddr, uint cash) public payable onlyOwner {
    investorCash += cash;
    Investor memory investor = Investor(invaddr, now, cash);
    investors[invaddr].push(investor);
    k = equityToken501c * investorCash;
  }

  function getTransactions() public view onlyOwner returns(string memory) {
    string memory output = "";

    for( uint i = 0; i < transactions[0].length; i++) {
      output = string(
        abi.encodePacked(output, "'", transactions[0][i].time, "','", transactions[0][i].sender, "',", transactions[0][i].amount, ",",  transactions[0][i].fee)
      );
    }
    return output;
  }

  function totalFees() public view onlyOwner returns(uint) {
    return total_fees;
  }

  function buy501CToken(uint _501cToBuy) public returns (uint cost) {
        equityToken501c -= _501cToBuy;
        uint newCashAmount = k / equityToken501c;
        uint fee = 1 / (fee_pct * 100);
        newCashAmount -= fee;
        require(newCashAmount >= parValue, "price must be at least par value");
        cost = newCashAmount - investorCash;
        total_fees += fee;
        investorCash += cost;
        Transaction memory transaction = Transaction(now, msg.sender, _501cToBuy, fee);
        transactions[0].push(transaction);
        return cost;
  }

  function sell501CTokens(uint _501cToSell) public returns (uint bought) {
        equityToken501c += _501cToSell;
        uint newCashAmount = k / equityToken501c;
        uint fee = 1 / (fee_pct * 100);
        newCashAmount -= fee;
        require(newCashAmount >= parValue, "price must be at least par value");
        bought = investorCash - newCashAmount;
        total_fees += fee;
        investorCash = newCashAmount;
        Transaction memory transaction = Transaction(now, msg.sender, _501cToSell, fee);
        transactions[0].push(transaction);
        return bought;
    }
}
