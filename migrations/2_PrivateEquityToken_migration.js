/**
 * Comment the private placement offerings that are not used.
 * Each private placement offering must have the proper SEC form filed with EDGAR
 */
var PrivateEquityOffering3A11 = artifacts.require('./PrivateEquityToken3A11');
var PrivateEquityOffering4A2 = artifacts.require('./PrivateEquityToken4A2');
var PrivateEquityOffering147 = artifacts.require('./PrivateEquityToken147');
var PrivateEquityOffering147A = artifacts.require('./PrivateEquityToken147A');
var PrivateEquityOffering504 = artifacts.require('./PrivateEquityToken504');
var PrivateEquityOffering505 = artifacts.require('./PrivateEquityToken505');
var PrivateEquityOffering506B = artifacts.require('./PrivateEquityToken506B');
var PrivateEquityOffering506C = artifacts.require('./PrivateEquityToken506C');
var PrivateEquityOfferingAT1 = artifacts.require('./PrivateEquityTokenAT1');
var PrivateEquityOfferingAT2 = artifacts.require('./PrivateEquityTokenAT2');

var IdentityRegistry = artifacts.require('./IdentityRegistry')

module.exports = function(deployer) {
    deployer.deploy(IdentityRegistry).then((A) => {
        deployer.deploy(PrivateEquityOffering3A11,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOffering4A2,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOffering147,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOffering147A,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOffering504,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOffering505,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOffering506B,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOffering506C,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOfferingAT1,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(PrivateEquityOfferingAT2,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
    })
}