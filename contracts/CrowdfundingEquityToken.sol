pragma solidity ^0.8.10;

/**
 * Regulation Crowdfunding; Section 4(a)(6)
 * ----------------------------------------
 * See https://www.sec.gov/info/smallbus/secg/rccomplianceguide-051316.htm
 *
 * c. Transactions Conducted Through an Intermediary
 *
 * Each Regulation Crowdfunding offering must be exclusively conducted through one online platform. The intermediary operating the platform must be a broker-dealer
 * or a funding portal that is registered with the SEC and FINRA.
 *
 * Issuers may rely on the efforts of the intermediary to determine that the aggregate amount of securities purchased by an investor does not cause the investor
 * to exceed the investment limits, so long as the issuer does not have knowledge that the investor would exceed the investment limits as a result of purchasing
 * securities in the issuer’s offering.
 */

// IMPORTANT NOTE: BECUASE OF THE REGULATIONS FOR CROWD FUNDING MUST BE CONDUCTED THROUGH AN INTERMEDIATARY THAT IS REGISTERED AS A BROKER-DEAKER OR FUNDING PORTAL WITH
// THE SEC AND FINRA, THIS CROWDFUNDING TOKEN IS USEFUL FOR ONLY A REGISTERED BROKER-DEALER OR FUNDING PORTAL THAT DESIRES TO OFFER A CRYPTOCURRENCY.

import "./token/ERC884/ERC884.sol";
import "./Time.sol";

contract CrowdfundingEquityToken is ERC884, MintableToken, Time {
    string public symbol;
    string public name;

    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);

    uint public decimals = 0;

    mapping(address => bytes32) private verified;
    mapping(address => address) private cancellations;
    mapping(address => uint256) private holderIndices;
    mapping(address => uint256) private transactions;

    address[] private shareholders;

    uint256 constant public creationTime = Time.createTime; // The contract creation time

    uint constant public parValue = 10;
    unit constant public totalValueMax = 1070000;
    uint constant public totalInvestorMax = 107000;
    uint private totalValue = 0;

    uint private year = 52 weeks;

    uint constant public totalInvestorMax = 107000;

    bool private restricted = true;

    constructor(string _symbol, string _name, uint _supply) {
      symbol = _symbol;
      name = _name;
      totalSupply_ = _supply;
    }

    modifier isVerifiedAddress(address addr) {
        require(verified[addr] != ZERO_BYTES, "address cannot be empty?");
        _;
    }

    modifier isShareholder(address addr) {
        require(holderIndices[addr] != 0, "address cannot be empty?");
        _;
    }

    modifier isNotShareholder(address addr) {
        require(holderIndices[addr] == 0, "address cannot be empty?");
        _;
    }

    modifier isNotCancelled(address addr) {
        require(cancellations[addr] == ZERO_ADDRESS, "address cannot be empty?");
        _;
    }

    modifier isOfferingExpired() {
      require(Time.currentTime < (creationTime * year),"offering has expired!");
    }

    modifier isPriceBelowParValue(uint amount) {
      require(amount > parValue, "amount is below par value");
    }

    modifier isInvestmentExceedLimit(uint amount) {
      require(amount < totalInvestorMax, "may not exceed $107,000");
    }


    modifier isRestrictedSecurity() {
      require(restricted != false, "security is restricted");
    }

    modifier hasHoldingTimeElapse(address addr) {
      for ( i = 0; i < transactions.length; i++ ) {
        if (transactions[i][0] == addr) {
          require(transactions[i][2] > (Time.currentTime * year),"minimum holding has not elapsed");
        }
      }
    }

    function CalculateInvestorLimit(uint amount, uint income, uint networth) internal {
      if (income < 107000) {
        uint fivepct_income = income * 0.05;
        uint fivepct_networth = networth * 0.05;

        if (fivepct_income <= fivepct_networth) {
          if (fivepct_income < 2200) {
            return 2200;
          } else {
            return fivepct_income;
          }
        } else {
          if (fivepct_networth < 2200) {
            return 2200;
          } else {
            return fivepct_networth;
          }
        }
      } else {
        uint tenpct_income = income * 0.1;
        uint tenpct_networth = networth * 0.1;

        if (tenpct_income <= tenpct_networth) {
          return tenpct_income;
        } else {
          return tenpct_networth;
        }
      }
    }

    function GetCurrentInvestment(address _address) internal {
      uint total = 0;
      for( i = 0; i < transactions.length; i++ ) {
        if (transactions[i][0] == _address) {
          total += transactions[1][1];
        }
      }
      return total;
    }

    /**
     * As each token is minted it is added to the shareholders array.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, uint income, uint networth)
        public
        onlyOwner
        canMint
        isOfferingExpired()
        isBelowParValue(_amount)
        isInvestmentExceedLimit(_amount)
        isInvestmentExceedLimit(GetCurrentInvestment(_to))
        returns (bool)
    {
        require(income, "missing annual income");
        require(networth, "missing net worth");
        // if the address does not already own share then
        // add the address to the shareholders array and record the index.
        updateShareholders(_to);

        // update totalValue
        require(totalValue <= totalValueMax,"maximum offering amount has been raised");
        totalValue += _amount;
        require(totalValue <= totalValueMax,"this sale will exceed the maximum offering limit");

        transactions.push([_to,_amount,Time.currentTime]);

        return super.mint(_to, _amount);
    }

    /**
    * From: https://ethereum.stackexchange.com/questions/11545/is-it-possible-to-access-storage-history-from-a-contract-in-solidity
    */
    function getValue(uint param) public returns (uint) {
        return totalValue;
    }

    /**
     *  The number of addresses that own tokens.
     *  @return the number of unique addresses that own tokens.
     */
    function holderCount()
        public
        onlyOwner
        view
        returns (uint)
    {
        return shareholders.length;
    }

    /**
     *  By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function holderAt(uint256 index)
        public
        onlyOwner
        view
        returns (address)
    {
        require(index < shareholders.length, "");
        return shareholders[index];
    }

    /**
     *  Add a verified address, along with an associated verification hash to the contract.
     *  Upon successful addition of a verified address, the contract must emit
     *  `VerifiedAddressAdded(addr, hash, msg.sender)`.
     *  It MUST throw if the supplied address or hash are zero, or if the address has already been supplied.
     *  @param addr The address of the person represented by the supplied hash.
     *  @param hash A cryptographic hash of the address holder's verified information.
     */
    function addVerified(address addr, bytes32 hash)
        public
        onlyOwner
        isNotCancelled(addr)
    {
        require(addr != ZERO_ADDRESS, "");
        require(hash != ZERO_BYTES, "");
        require(verified[addr] == ZERO_BYTES, "");
        verified[addr] = hash;
        emit VerifiedAddressAdded(addr, hash, msg.sender);
    }

    /**
     *  Remove a verified address, and the associated verification hash. If the address is
     *  unknown to the contract then this does nothing. If the address is successfully removed, this
     *  function must emit `VerifiedAddressRemoved(addr, msg.sender)`.
     *  It MUST throw if an attempt is made to remove a verifiedAddress that owns Tokens.
     *  @param addr The verified address to be removed.
     */
    function removeVerified(address addr)
        public
        onlyOwner
    {
        require(balances[addr] == 0, "");
        if (verified[addr] != ZERO_BYTES) {
            verified[addr] = ZERO_BYTES;
            emit VerifiedAddressRemoved(addr, msg.sender);
        }
    }

    /**
     *  Update the hash for a verified address known to the contract.
     *  Upon successful update of a verified address the contract must emit
     *  `VerifiedAddressUpdated(addr, oldHash, hash, msg.sender)`.
     *  If the hash is the same as the value already stored then
     *  no `VerifiedAddressUpdated` event is to be emitted.
     *  It MUST throw if the hash is zero, or if the address is unverified.
     *  @param addr The verified address of the person represented by the supplied hash.
     *  @param hash A new cryptographic hash of the address holder's updated verified information.
     */
    function updateVerified(address addr, bytes32 hash)
        public
        onlyOwner
        isVerifiedAddress(addr)
    {
        require(hash != ZERO_BYTES, "");
        bytes32 oldHash = verified[addr];
        if (oldHash != hash) {
            verified[addr] = hash;
            emit VerifiedAddressUpdated(addr, oldHash, hash, msg.sender);
        }
    }

    /**
     *  Cancel the original address and reissue the Tokens to the replacement address.
     *  Access to this function MUST be strictly controlled.
     *  The `original` address MUST be removed from the set of verified addresses.
     *  Throw if the `original` address supplied is not a shareholder.
     *  Throw if the replacement address is not a verified address.
     *  This function MUST emit the `VerifiedAddressSuperseded` event.
     *  @param original The address to be superseded. This address MUST NOT be reused.
     *  @param replacement The address  that supersedes the original. This address MUST be verified.
     */
    function cancelAndReissue(address original, address replacement)
        public
        onlyOwner
        isShareholder(original)
        isNotShareholder(replacement)
    {
        // replace the original address in the shareholders array
        // and update all the associated mappings
        verified[original] = ZERO_BYTES;
        cancellations[original] = replacement;
        uint256 holderIndex = holderIndices[original] - 1;
        shareholders[holderIndex] = replacement;
        holderIndices[replacement] = holderIndices[original];
        holderIndices[original] = 0;
        balances[replacement] = balances[original];
        balances[original] = 0;
        emit VerifiedAddressSuperseded(original, replacement, msg.sender);
    }

    /**
     *  The `transfer` function MUST NOT allow transfers to addresses that
     *  verification is NOT needed for 504 rule.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    function transfer(address to, uint256 value)
        public
        isRestrictedSecurity()
        isHolder(msg.sender)
        hasHoldingTimeElapse(msg.sender)
        returns (bool)
    {
        updateShareholders(to);
        pruneShareholders(msg.sender, value);
        return super.transfer(to, value);
    }

    /**
     *  The `transferFrom` function MUST NOT allow transfers to addresses that
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `from`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        isRestrictedSecurity()
        isHolder(from)
        hasHoldingTimeElapse(from)
        returns (bool)
    {
        updateShareholders(to);
        pruneShareholders(from, value);
        return super.transferFrom(from, to, value);
    }

    /**
     *  Tests that the supplied address is known to the contract.
     *  @param addr The address to test.
     *  @return true if the address is known to the contract.
     */
    function isVerified(address addr)
        public
        view
        returns (bool)
    {
        return verified[addr] != ZERO_BYTES;
    }

    /**
     *  Checks to see if the supplied address is a share holder.
     *  @param addr The address to check.
     *  @return true if the supplied address owns a token.
     */
    function isHolder(address addr)
        public
        view
        returns (bool)
    {
        return holderIndices[addr] != 0;
    }

    /**
     *  Checks that the supplied hash is associated with the given address.
     *  @param addr The address to test.
     *  @param hash The hash to test.
     *  @return true if the hash matches the one supplied with the address in `addVerified`, or `updateVerified`.
     */
    function hasHash(address addr, bytes32 hash)
        public
        view
        returns (bool)
    {
        if (addr == ZERO_ADDRESS) {
            return false;
        }
        return verified[addr] == hash;
    }

    /**
     *  Checks to see if the supplied address was superseded.
     *  @param addr The address to check.
     *  @return true if the supplied address was superseded by another address.
     */
    function isSuperseded(address addr)
        public
        view
        onlyOwner
        returns (bool)
    {
        return cancellations[addr] != ZERO_ADDRESS;
    }

    /**
     *  Gets the most recent address, given a superseded one.
     *  Addresses may be superseded multiple times, so this function needs to
     *  follow the chain of addresses until it reaches the final, verified address.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function getCurrentFor(address addr)
        public
        view
        onlyOwner
        returns (address)
    {
        return findCurrentFor(addr);
    }

    /**
     *  Recursively find the most recent address given a superseded one.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function findCurrentFor(address addr)
        internal
        view
        returns (address)
    {
        address candidate = cancellations[addr];
        if (candidate == ZERO_ADDRESS) {
            return addr;
        }
        return findCurrentFor(candidate);
    }

    /**
     *  If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param addr The address to add as a shareholder if it's not already.
     */
    function updateShareholders(address addr)
        internal
    {
        if (holderIndices[addr] == 0) {
            holderIndices[addr] = shareholders.push(addr);
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param addr The address to prune if their balance will be reduced to 0.
     @  @dev see https://ethereum.stackexchange.com/a/39311
     */
    function pruneShareholders(address addr, uint256 value)
        internal
    {
        uint256 balance = balances[addr] - value;
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
        // overwrite the addr's slot with the last shareholder
        shareholders[holderIndex] = lastHolder;
        // also copy over the index (thanks @mohoff for spotting this)
        // ref https://github.com/davesag/ERC884-reference-implementation/issues/20
        holderIndices[lastHolder] = holderIndices[addr];
        // trim the shareholders array (which drops the last entry)
        shareholders.length--;
        // and zero out the index for addr
        holderIndices[addr] = 0;
    }
}
