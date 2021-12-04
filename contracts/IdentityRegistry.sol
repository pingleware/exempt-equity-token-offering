pragma solidity ^0.8.10;

import "./Whitelistable.sol";

contract IdentityRegistry is Whitelistable {
    mapping(address => string) public identityMap; // maps an address to an idenity hash

    event IdentityAdded(address indexed addressAdded, string identityHash, address indexed authorizedBy);
    event IdentityUpdated(address indexed updatedAddress, string previousHash, string newHash, address indexed authorizedBy);

    constructor()  Whitelistable(){ 
      // empty constructor used to call the whitelistable constructor
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function addIdentity(address _address, string memory hash, string memory investor_type) onlyOwner() public {
        bytes memory value = bytes(identityMap[_address]);
        require(value.length == 0, "This identity was registered already");

        identityMap[_address] = hash;
        if (compareStrings(investor_type, "accredited")) {
            addAddressToWhitelist(_address);
        } else if (compareStrings(investor_type,"affiliate")) {
            addAddressToAffiliateList(_address);
        } else {
            addAddressToPublicInvestorList(_address);
        }
        emit IdentityAdded(_address, hash, msg.sender);
    }

    function updateIdentity(address updatedAddress, string memory newHash) onlyOwner() public {
        bytes memory previousHash = bytes(identityMap[updatedAddress]);
        require(previousHash.length != 0);
        identityMap[updatedAddress] = newHash;
        emit IdentityUpdated(updatedAddress, string(previousHash), newHash, msg.sender);
    }
}