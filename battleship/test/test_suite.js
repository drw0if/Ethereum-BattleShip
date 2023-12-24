const TestSuite = artifacts.require("TestSuite");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("TestSuite", function (/* accounts */) {
  it("should assert true", async function () {
    await TestSuite.deployed();
    return assert.isTrue(true);
  });
});
