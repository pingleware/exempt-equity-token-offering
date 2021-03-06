// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.5.11;

/**
 * Intrastate: Rule 147
 * --------------------
 * See https://www.sec.gov/smallbusiness/exemptofferings/intrastateofferings
 *
 * Rule 147 is considered a “safe harbor” under Section 3(a)(11),
 * providing objective standards that a company can rely on to meet the requirements of
 * that exemption. Rule 147, as amended, has the following requirements:
 *
 *  - the company must be organized in the state where it offers and sells securities
 *  - the company must have its “principal place of business” in-state and satisfy at least one “doing business” requirement that demonstrates the in-state
 *    nature of the company’s business
 *  - offers and sales of securities can only be made to in-state residents or persons who the company reasonably believes are in-state residents and
 *  - the company obtains a written representation from each purchaser providing the residency of that purchaser
 *
 * Securities purchased in an offering under Rule 147 limit resales to persons residing within the state of the offering for a period of six months
 * from the date of the sale by the issuer to the purchaser. In addition, a company must comply with state securities laws and regulations in the states
 * in which securities are offered or sold.
 * 
 * Intrastate: Rule 147A
 * ---------------------
 * See https://www.sec.gov/smallbusiness/exemptofferings/intrastateofferings
 *
 * Rule 147A is a new intrastate offering exemption adopted by the Commission in
 * October 2016. Rule 147A is substantially identical to Rule 147 except that Rule 147A:
 *
 *  - allows offers to be accessible to out-of-state residents, so long sales are only made to in-state residents and
 *  - permits a company to be incorporated or organized out-of-state, so long as the company has its “principal place of business” in-state
 *    and satisfies at least one “doing business” requirement that demonstrates the in-state nature of the company’s business
 */

/**
* Under 147
* ---------
* Example: a company must be incorporated and doing business in Florida and can only offer a private equity exempt offering to the residents of
* Florida ONLY!
*
* Under 147-A
* -----------
* Example: a company may be incorporated in Delaware and doing business in Florida, and hence may offer private equity sales in Florida as long as
* they meet the "doing business" criteria. If business meets the "doing business" requirement for both states, then a private equity offering
* may be offered to the residents of both the state of Delaware and Florida.
*/

import '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import './token/ERC884.sol';
import "./token/Time.sol";

contract ExemptEquityToken147  is ERC884, ERC20Mintable {
    string public constant name = "Rule 147 Token";
    string public constant symbol = "TOKEN.147";
    uint8 public constant decimals = 0;

    uint public constant INITIAL_SUPPLY = 100000 * 1 ether;

    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);

    mapping(address => bytes32) private verified;
    mapping(address => address) private cancellations;
    mapping(address => uint256) private holderIndices;
    mapping (address => uint256) public balances;

    struct Transaction {
        address addr;
        uint256 amount;
        uint256 time;
    }

    mapping(address => Transaction[]) public transactions;

    address private owner;

    address[] private shareholders;

    bool internal active = false;
    uint256 private start_timestamp;
    event ExemptOffering(address indexed from,string status, uint256 value);

    uint constant public parValue = 5 * 0.001 ether;
    uint constant public totalValueMax = 100000 * parValue;
    uint private totalValue = 0;

    uint256 private contract_creation; // The contract creation time

    bool private restricted = true;

    uint private year = 52 weeks;
    uint private sixmonths = 26 weeks;

    event Bought(uint value);
    event Sold(uint value);

    constructor() public {
        contract_creation = now;
        owner = msg.sender;
        addMinter(owner);
        _mint(owner, INITIAL_SUPPLY);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "access denied");
        _;
    }

    modifier canMint() {
        require(isMinter(msg.sender),"access denied");
        _;
    }

    modifier isActive() {
        require(active, "exempt offering is not active");
        _;
    }

    modifier isVerifiedAddress(address addr) {
        require(verified[addr] != ZERO_BYTES, "");
        _;
    }

    modifier isShareholder(address addr) {
        require(holderIndices[addr] != 0, "");
        _;
    }

    modifier isNotShareholder(address addr) {
        require(holderIndices[addr] == 0, "");
        _;
    }

    modifier isNotCancelled(address addr) {
        require(cancellations[addr] == ZERO_ADDRESS, "");
        _;
    }

    modifier isOfferingExpired() {
      require(now < (contract_creation + sixmonths),"offering has expired!");
      _;
    }

    modifier isPriceBelowParValue(uint amount) {
      require(amount > parValue, "amount is below par value");
      _;
    }

    modifier isRestrictedSecurity() {
      require(restricted != false, "security is restricted");
      _;
    }

    modifier isHoldingPeriodOver(address addr) {
        bool over = false;
        for (uint i = 0; i < transactions[addr].length; i++) {
            if (transactions[addr][i].time > (transactions[addr][i].time + sixmonths)) {
                over = true;
            }
        }
        require (over, "holding period is not over");
        _;
    }

    /**
     * As each token is minted it is added to the shareholders array.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount)
        public
        isActive
        onlyOwner
        canMint
        isVerifiedAddress(_to)
        isPriceBelowParValue(_amount)
        returns (bool)
    {
        // if the address does not already own share then
        // add the address to the shareholders array and record the index.
        updateShareholders(_to);
        Transaction memory trans = Transaction(_to, _amount, now);
        transactions[_to].push(trans);
        return super.mint(_to, _amount);
    }

    function toggleExemptOffering(uint256 timestamp, bool _active)
        public
        onlyOwner
    {
        start_timestamp = timestamp;
        active = _active;

        if (active) {
            emit ExemptOffering(msg.sender, string(abi.encodePacked(name, " has started")), timestamp);
        } else {
            emit ExemptOffering(msg.sender, string(abi.encodePacked(name, " has stopped")), timestamp);
        }
    }

    function getTransactions(address addr) public view onlyOwner returns (string memory) {
        string memory output = "";
        for (uint i = 0; i < transactions[addr].length; i++) {
            output = string(
                abi.encodePacked(output, "[", transactions[addr][i].addr, ",", transactions[addr][i].amount, ",",  transactions[addr][i].time, "]")
            );
        }
        return output;
    }

    function getTransactionByIndex(address addr, uint index) public view onlyOwner returns (string memory) {
        return string(abi.encodePacked(
            "[", transactions[addr][index].addr, ",", transactions[addr][index].amount, ",", transactions[addr][index].time, "]"
        ));
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
        require(addr.balance == 0, "account balance is not zero");
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
        isActive
        onlyOwner
        isShareholder(original)
        isNotShareholder(replacement)
        isVerifiedAddress(replacement)
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
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    function transfer(address to, uint256 value)
        public
        isActive
        isVerifiedAddress(to)
        isHoldingPeriodOver(to)
        returns (bool)
    {
        updateShareholders(to);
        pruneShareholders(msg.sender, value);
        Transaction memory trans = Transaction(to, value, now);
        transactions[to].push(trans);
        trans = Transaction(msg.sender, uint256(-1) * value, now);
        transactions[msg.sender].push(trans);

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
        isActive
        isVerifiedAddress(to)
        isHoldingPeriodOver(from)
        returns (bool)
    {
        updateShareholders(to);
        pruneShareholders(from, value);
        Transaction memory trans = Transaction(to, value, now);
        transactions[to].push(trans);
        trans = Transaction(from, uint256(-1) * value, now);
        transactions[from].push(trans);

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
        uint256 balance = addr.balance - value;
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

    function buy()
        public
        payable
        isActive
        isVerifiedAddress(msg.sender)
    {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        Transaction memory trans = Transaction(msg.sender, amountTobuy, now);
        transactions[msg.sender].push(trans);
        transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount)
        public
        payable
        isActive
        isVerifiedAddress(msg.sender)
        isHoldingPeriodOver(msg.sender)
    {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        transferFrom(msg.sender, address(this), amount);
        Transaction memory trans = Transaction(msg.sender, amount, now);
        transactions[msg.sender].push(trans);
        msg.sender.transfer(amount);
        emit Sold(amount);
    }

}