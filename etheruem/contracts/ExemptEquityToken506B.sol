// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.5.11;

/**
 * Rule 506(b)
 * -----------
 * https://www.sec.gov/smallbusiness/exemptofferings/
 *
 * Rule 506(b) of Regulation D is considered a “safe harbor” under Section 4(a)(2). It provides objective standards that a company can rely on to meet the requirements
 * of the Section 4(a)(2) exemption. Companies conducting an offering under Rule 506(b) can raise an unlimited amount of money and can sell securities to an
 * unlimited number of accredited investors. An offering under Rule 506(b), however, is subject to the following requirements:
 *
 *  - no general solicitation or advertising to market the securities
 *  - securities may not be sold to more than 35 non-accredited investors (all non-accredited investors, either alone or with a purchaser representative,
 *    must meet the legal standard of having sufficient knowledge and experience in financial and business matters to be capable of evaluating the merits and
 *    risks of the prospective investment)
 *
 * If non-accredited investors are participating in the offering, the company conducting the offering:
 *
 *  - must give any non-accredited investors disclosure documents that generally contain the same type of information as provided in Regulation A offerings
 *    (the company is not required to provide specified disclosure documents to accredited investors, but, if it does provide information to accredited investors,
 *    it must also make this information available to the non-accredited investors as well)
 *  - must give any non-accredited investors financial statement information specified in Rule 506 and
 *  - should be available to answer questions from prospective purchasers who are non-accredited investors
 *
 * Purchasers in a Rule 506(b) offering receive “restricted securities." A company is required to file a notice with the Commission on Form D within 15 days
 * after the first sale of securities in the offering. Although the Securities Act provides a federal preemption from state registration and qualification
 * under Rule 506(b), the states still have authority to require notice filings and collect state fees.
 */
import '@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol';
import './token/ERC884.sol';

contract ExemptEquityToken506B is ERC884, ERC20Mintable {
    string public constant name = "Rule 506(b) Token";
    string public constant symbol = "TOKEN.506B";
    uint8 public constant decimals = 0;

    uint public constant INITIAL_SUPPLY = 100000 * 1 ether;

    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);


    mapping(address => bytes32) private verified;
    mapping(address => address) private cancellations;
    mapping(address => uint256) private holderIndices;
    mapping(address => uint256) public  balances;

    struct Transaction {
        address addr;
        uint256 amount;
        uint256 time;
    }

    mapping(address => Transaction[]) public transactions;

    address private owner;

    address[] private shareholders;
    address[] private shareholders_nonacredited;
    address[] private shareholders_affiliate;


    bool internal active = false;
    uint256 private start_timestamp;
    event ExemptOffering(address indexed from,string status, uint256 value);
    event Bought(uint value);
    event Sold(uint value);

    uint constant public parValue = 10;
    uint256 constant public totalValueMax = 5000000;
    uint constant public maxNonaccredited = 35;
    uint256 private totalValue = 0;

    bool private restricted = true;

    constructor() public {
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

    modifier isPriceBelowParValue(uint amount) {
      require(amount > parValue, "amount is below par value");
      _;
    }

    modifier isRestrictedSecurity() {
      require(restricted != false, "security is restricted");
      _;
    }

    modifier isMaximumOffering(uint256 amount) {
        require(totalValue + amount < totalValueMax, "maximum offering has been reached");
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
        isMaximumOffering(_amount)
        returns (bool)
    {
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
        isPriceBelowParValue(value)
        returns (bool)
    {
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
        isPriceBelowParValue(value)
        returns (bool)
    {
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

    function addShareholder(address addr, uint level)
        public
        onlyOwner
    {
        if (holderIndices[addr] == 0) {
            if (level == 0) {
                require(shareholders_nonacredited.length < maxNonaccredited, "will exceed the maximum number of non-accredited investors");
                holderIndices[addr] = shareholders_nonacredited.push(addr);
            } else if (level == 1) {
                holderIndices[addr] = shareholders.push(addr);
            } else if (level == 2) {
                holderIndices[addr] = shareholders_affiliate.push(addr);
            }
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
        isMaximumOffering(msg.value)
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