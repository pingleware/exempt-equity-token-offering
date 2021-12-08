// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.5.11;

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

// An example of a crowdfunding token at https://github.com/JincorTech/ico/blob/master/contracts/JincorToken.sol

import "./token/Burnable.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";


contract CrowdfundingEquityToken is Burnable, Ownable {
    string public constant name = "Crowdfunding Token";
    string public constant symbol = "TOKEN.CF";
    uint8 public constant decimals = 0;
    uint256 public constant INITIAL_SUPPLY = 100000 * 1 ether;

    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);

    /* The finalizer contract that allows unlift the transfer limits on this token */
    address public releaseAgent;

    /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
    bool public released = false;

    /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
    mapping (address => bool) public transferAgents;

    mapping (address => uint256) public balances;
    /**
    * Limit token transfer until the crowdsale is over.
    *
    */
    modifier canTransfer(address _sender) {
        require(released || transferAgents[_sender], "");
        _;
    }

    /** The function can be called only before or after the tokens have been released */
    modifier inReleaseState(bool releaseState) {
        require(releaseState == released, "");
        _;
    }

    /** The function can be called only by a whitelisted release agent. */
    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent, "");
        _;
    }


      /**
       * @dev Constructor that gives msg.sender all of existing tokens.
       */
    constructor() public {
        balances[msg.sender] = INITIAL_SUPPLY;
        _mint(msg.sender, INITIAL_SUPPLY);
    }


    /**
    * Set the contract that can call release and make the token transferable.
    *
    * Design choice. Allow reset the release agent to fix fat finger mistakes.
    */
    function setReleaseAgent(address addr) public onlyOwner inReleaseState(false) {
        require(addr != ZERO_ADDRESS, "");

        // We don't do interface check here as we might want to a normal wallet address to act as a release agent
        releaseAgent = addr;
    }

    function release() public onlyReleaseAgent inReleaseState(false) {
        released = true;
    }

    /**
    * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
    */
    function setTransferAgent(address addr, bool state) public onlyOwner inReleaseState(false) {
        require(addr != ZERO_ADDRESS, "");
        transferAgents[addr] = state;
    }

    function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
        // Call Burnable.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
        // Call Burnable.transferForm()
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint _value) public onlyOwner returns (bool success) {
        return super.burn(_value);
    }

    function burnFrom(address _from, uint _value) public onlyOwner returns (bool success) {
        return super.burnFrom(_from, _value);
    }
}
