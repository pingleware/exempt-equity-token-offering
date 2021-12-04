# Creating a Smart Contract 
To begin creating a smart contract you will need the following tools,

    npx truffle init
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