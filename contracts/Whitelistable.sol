pragma solidity ^0.8.10;


contract Whitelistable {
    mapping (address => bool) public whitelist;
    mapping (address => bool) public public_investor;
    mapping (address => bool) public affiliates;

    address public owner;
    
    event AddressAddedToWhitelist(address indexed AuthorizedBy, address indexed AddressAdded);
    event AddressRemovedFromWhitelist(address indexed AuthorizedBy, address indexed AddressRemoved);
    event AddressAddedToPublicInvestorList(address indexed AuthorizedBy, address indexed AddressAdded);
    event AddressRemovedFromPublicInvestorList(address indexed AuthorizedBy, address indexed AddressRemoved);
    event AddressAddedToAffiliateList(address indexed AuthorizedBy, address indexed AddressAdded);
    event AddressRemovedFromAffiliateList(address indexed AuthorizedBy, address indexed AddressRemoved);

    modifier onlyOwner() { // modifier to restrict access only the owner of the contract
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    
    function isWhitelisted(address _address) public view returns(bool){ // function to check if address is whitelisted
        return whitelist[_address];
    }

    function isPublicInvestor(address _address) public view returns(bool){
        return public_investor[_address];
    }

    function isAffiliate(address _address) public view returns(bool) { // function to check is an affiliate
        return affiliates[_address];
    }

    function addAddressToWhitelist(address _address) onlyOwner public{ // add an address to the authorized mapping
        require(!isWhitelisted(_address));
        whitelist[_address] = true;
        emit AddressAddedToWhitelist(msg.sender, _address);
    }

    // this meets KYC compliance, as the investor must be whitelisted whether
    // they are accredited or not?
    function addAddressToPublicInvestorList(address _address) onlyOwner public {
        require(!isWhitelisted(_address));
        public_investor[_address] = true;
        emit AddressAddedToPublicInvestorList(msg.sender, _address);
    }

    function addAddressToAffiliateList(address _address) onlyOwner public {
        require(!isAffiliate(_address));
        affiliates[_address] = true;
        emit AddressAddedToAffiliateList(msg.sender, _address);
    }

    function removeAddressFromWhitelist(address _address) onlyOwner public{
        require(isWhitelisted(_address)); // check if address is whitelisted
        whitelist[_address] = false;
        emit AddressRemovedFromWhitelist(msg.sender, _address);
    }

    function removeAddressFromPublicInvestorList(address _address) onlyOwner public {
        require(isWhitelisted(_address)); // check if address is whitelisted
        public_investor[_address] = false;
        emit AddressRemovedFromPublicInvestorList(msg.sender, _address);
    }

    function removeAddressFromAffiliateList(address _address) onlyOwner public {
        require(isAffiliate(_address));
        affiliates[_address] = false;
        emit AddressRemovedFromAffiliateList(msg.sender, _address);
    }
}
