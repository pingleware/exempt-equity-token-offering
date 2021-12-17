# Creating a Smart Contract 
To begin creating a smart contract you will need the following tools,

    npx truffle init (or truffle init)
    npm init -y

# Developing with Truffle Develop
To start with developing, enter the truffle space,

    > truffle develop

you will see the prompt

    truffle(develop)>

now create the following contracts: Whitelistable

    truffle(develop)> create contract Whitelistable
    truffle(develop)> create contract IdentityRegistry
    truffle(develop)> create contract StockToken

a new files is created in the contracts directory

    Whitelistable.sol
    IdentityRegistry.sol
    StockToken.sol


# Developing with Ganache-UI
During the development of this Private Placement equity token, the Ganache-UI private blockchain will be used.

# Ganache-CLI
To launch from the command line,

    ganache-cli --port="8545" --mnemonic "copy obey episode awake damp vacant protect hold wish primary travel shy" --verbose --networkId=3 --gasLimit=7984452 --gasPrice=2000000000;

# Workflow Plan
The following is a high order overview of the workflow plan,

    1. Develop a suitable smart contract that meets the requirements for Reg D Rule 506C on the Ethereum test network
    2. Out source an independent audit of the smart contract
    3. Update Articles of Incorporation to increase authroized shares to 1,000,000,000,000 with a par value of $5. [In Florida, see Chapter 607 FLORIDA BUSINESS CORPORATION ACT at http://www.leg.state.fl.us/statutes/index.cfm?mode=View%20Statutes&SubMenu=1&App_mode=Display_Statute&Search_String=607.0202&URL=0600-0699/0607/Sections/0607.0202.html]
    4. Register as a Transfer Agent with the SEC by completing form TA-1
    5. Prepare the Private Placement Memorandum with an attorney review and correction, if needed?
    6. Create a new Form D filing on SEC EDGAR Filing system with references to this code repository
    7. Apply for a CUSIP for the exempt offering.
    8. Submit the Solicitation Materials Used in Rule 506(c) Offerings to https://www.sec.gov/forms/rule506c#no-back
    9. Deploy the smart contract to the Ethereum main net
    10. Contact preselected accredited investors.
