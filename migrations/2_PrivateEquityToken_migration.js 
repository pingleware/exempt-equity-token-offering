var PrivateEquityStock = artifacts.require('./PrivateEquityToken506C');
var IdentityRegistry = artifacts.require('./IdentityRegistry')

module.exports = function(deployer) {
    deployer.deploy(IdentityRegistry).then((A) => {
        deployer.deploy(PrivateEquityStock,'SYMBOL','NAME',100000, 'OWNER_ADDRESS',A.address);
    })
}