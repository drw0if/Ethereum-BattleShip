var BattleShip = artifacts.require("../contracts/BattleShip.sol");

module.exports = function (deployer) {
  deployer.deploy(BattleShip);
}
