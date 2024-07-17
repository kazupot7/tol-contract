const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenFactory", function () {
   let tokenFactory;
   let owner, addr1;

   beforeEach(async function () {
      [owner, addr1] = await ethers.getSigners();
      const TokenFactory = await ethers.getContractFactory("TokenFactory");
      tokenFactory = await TokenFactory.deploy();
   });

   it("should create a token", async function () {
      const name = "One Top";
      const symbol = "OT";
      const initialSupply = ethers.parseEther("1000");

      // Create a token
      await tokenFactory.createToken(name, symbol, initialSupply);

      // Get the address of the created token from the emitted event
      const filter = tokenFactory.filters.TokenCreated();
      const events = await tokenFactory.queryFilter(filter);
      const tokenAddress = events[0].args.tokenAddress;

      const token = await ethers.getContractAt("ERC20Token", tokenAddress);
      const ownerBalance = await token.balanceOf(owner.address);
      expect(await token.totalSupply()).to.equal(ownerBalance);
   });
});
