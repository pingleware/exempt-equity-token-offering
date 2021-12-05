/**
 * Comment the Exempt placement offerings that are not used.
 * Each Exempt placement offering must have the proper SEC form filed with EDGAR
 */
var ExemptEquityOffering3A11 = artifacts.require('./ExemptEquityToken3A11');
var ExemptEquityOffering4A2 = artifacts.require('./ExemptEquityToken4A2');
var ExemptEquityOffering147 = artifacts.require('./ExemptEquityToken147');
var ExemptEquityOffering504 = artifacts.require('./ExemptEquityToken504');
var ExemptEquityOffering505 = artifacts.require('./ExemptEquityToken505');
var ExemptEquityOffering506B = artifacts.require('./ExemptEquityToken506B');
var ExemptEquityOffering506C = artifacts.require('./ExemptEquityToken506C');
var ExemptEquityOfferingAT1 = artifacts.require('./ExemptEquityTokenAT1');
var ExemptEquityOfferingAT2 = artifacts.require('./ExemptEquityTokenAT2');

var IdentityRegistry = artifacts.require('./IdentityRegistry')

module.exports = function(deployer) {
    deployer.deploy(IdentityRegistry).then((A) => {
        deployer.deploy(ExemptEquityOffering3A11,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOffering4A2,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOffering147,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOffering504,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOffering505,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOffering506B,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOffering506C,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOfferingAT1,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
        deployer.deploy(ExemptEquityOfferingAT2,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
    })
}