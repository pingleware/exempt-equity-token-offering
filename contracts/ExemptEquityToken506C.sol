pragma solidity ^0.8.10;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IdentityRegistry.sol";
import "./token/ERC884/ERC884.sol";
import "./Whitelistable.sol";
import "./IERC20GetImageSvg.sol";
import "./Time.sol";

contract ExemptEquityToken506C is ERC884, Whitelistable, IERC20GetImageSvg, Time {

    string public symbol;
    string public name;
    string public byLawsHash;
    address public owner;
    uint public decimals;
    bool public isPrivateCompany = true;
    mapping(address => uint) tokenOwnersIndex;
    address[] public tokenOwners;
    IdentityRegistry public platformWhitelist;

    string[] public _tokenImageSvg;

    string[] public _form144ImageSvg;

    uint256 public _holdingTime = Time.createTime + (52 * 1 weeks);

    uint public _parValue = 10;

    event ChangedCompanyStatus(address authorizedBy, bool newStatus);
    
    constructor(string _symbol, string _name, uint _supply, string hash, address _registry,string calldata svgCode) Whitelistable() {
        symbol = _symbol;
        name = _name;
        totalSupply_ = _supply;
        byLawsHash = hash;
        owner = msg.sender;
        addAddressToAffiliateList(owner); // add the owner to the Affiliate list
        balances[msg.sender] = _supply;
        platformWhitelist = IdentityRegistry(_registry);
        tokenOwners.push(0);
        uint index = tokenOwners.push(msg.sender);
        tokenOwnersIndex[msg.sender] = index - 1;

        _tokenImageSvg[_registry] = svgCode;
    }

    /**
     * @dev Returns the Stock Certificate image
     */
    function getTokenImageSvg(address _address) external view returns (string memory) {
        return _tokenImageSvg[_address];
    } 

    /**
     * @dev Returns the Form 144 image for affiliate trading 
     */
    function getForm144ImageSvg(address _address) external view returns (string memory) {
        return _form144ImageSvg[_address];
    }

    modifier onlyIfWhitelisted(address _address) { // modifier to restrict access only to whitelisted accounts
        require(platformWhitelist.isWhitelisted(_address));
        if(isPrivateCompany){
            // Verify if current timestamp has pass the holding time?
            if (block.timestamp > _holdingTime) {
                require (isWhitelisted(_address) || isPublicInvestor(_address) || isAffiliate(_address));
            } else {
                require(isWhitelisted(_address)  || isAffiliate(_address), "Address not in accredited nor affiliate shareholders whitelist");
            }
        }
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function transfer(address _to, uint256 _value, string calldata _svgCode) onlyIfWhitelisted(_to) public returns (bool){
        require(_value >= _parValue, "Price must be equal or greater than the par value!");

        uint index = 0;
        if(tokenOwnersIndex[_to] == 0) {
            index = tokenOwners.push(_to) - 1;
            tokenOwnersIndex[_to] = index;
        }
        // if contract owner is selling, then affiliate trade activity and requires form 144
        // to attached?
        if (isAffilate(msg.sender)) {
            require(_value <= (totalSupply_ * 0.1),"Affiliate trade may only sell 10% or less of the outstanding shares!"); // Ensure the amount for an affiliate trade does not exceed 10% of the outstanding shares?
            _form144ImageSvg[msg.sender] = _svgCode;
        }
        super.transfer(_to, _value);
    }

    function togglePrivateCompany() onlyOwner() public {
        isPrivateCompany = !isPrivateCompany;
        emit ChangedCompanyStatus(msg.sender, isPrivateCompany);
    }

    // Return the number of shareholders in the company
    function ownersCount() public view returns(uint){
        return tokenOwners.length - 1;
    }
    
    // Return an array with all the token owners
    function getTokenOwners() public view returns(address[]){
        return tokenOwners;
    }

    // Removes entry from array at index and resizes the array appropriatly
    function removeFromTokenOwnersArray(uint index) internal {
        address lastElement = tokenOwners[tokenOwners.length - 1];
        tokenOwners[index] = lastElement;
        tokenOwners.length--;
    }

    // Removes a token owner from the list of shareholders
    function removeTokenOwner(address holder) internal {
        uint i = tokenOwnersIndex[holder];
        removeFromTokenOwnersArray(i);
        tokenOwnersIndex[holder] = 0;
    }

    function cancelAndReissue(address original, address replacement) onlyOwner() public returns (bool) {
        require(isWhitelisted(original) || isPublicInvestor(original) || isAffilate(original), "Address is not a whitelisted shareholder?");
        require(tokenOwnersIndex[original], "Address does not owned any shares?");

        uint index = 0;
        if(tokenOwnersIndex[replacement] == 0) {
            index = tokenOwners.push(replacement) - 1;
            tokenOwnersIndex[replacement] = index;
        }
        
        if (isWhitelisted(original)) {
            addAddressToWhitelist(replacement);
        } else if(isAffiliate(original)) {
            addAddressToAffiliateList(replacement);
        } else {
            addAddressToPublicInvestorList(replacement);
        }

        balances[replacement] = balances[original]; // copies original balance to replacement
        balances[original] = 0; // zeros original balance

        removeTokenOwner(original);

        emit Transfer(original, replacement, balances[replacement]);
    }

    /**
    * From: https://ethereum.stackexchange.com/questions/11545/is-it-possible-to-access-storage-history-from-a-contract-in-solidity
    */
    function getValue(uint param) public returns (uint) {
        return 0;
    }
}