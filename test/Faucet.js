const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Faucet", function () {
   let Faucet, faucet, Token, token, owner, addr1, addr2;

   beforeEach(async function () {
      [owner, addr1, addr2] = await ethers.getSigners();

      // Deploy the ERC20 token
      Token = await ethers.getContractFactory("TOLToken");
      token = await Token.deploy();

      // Deploy the Faucet
      Faucet = await ethers.getContractFactory("Faucet");
      faucet = await Faucet.deploy(
         token.target,
         ethers.parseEther("100"),
         3600
      ); // Claim amount: 100 tokens, Interval: 1 hour

      // Mint tokens to the Faucet contract
      await token.mint(faucet.target, ethers.parseEther("1000"));
      await token.mint(owner.address, ethers.parseEther("100"));
   });

   describe("Deployment", function () {
      it("Should set the correct parameters", async function () {
         expect(await faucet.token()).to.equal(token.target);
         expect(await faucet.claimAmount()).to.equal(ethers.parseEther("100"));
         expect(await faucet.claimInterval()).to.equal(3600);
      });
   });

   describe("Claiming Tokens", function () {
      it("Should allow claiming tokens if interval has passed", async function () {
         await faucet.connect(addr1).claimTokens();
         await network.provider.send("evm_increaseTime", [3600]); // Increase time by 1 hour
         await network.provider.send("evm_mine"); // Mine a new block

         await expect(faucet.connect(addr1).claimTokens())
            .to.emit(faucet, "TokensClaimed")
            .withArgs(addr1.address, ethers.parseEther("100"));

         const addr1Balance = await token.balanceOf(addr1.address);
         expect(addr1Balance).to.equal(ethers.parseEther("200"));
      });

      it("Should not allow claiming tokens if interval has not passed", async function () {
         await faucet.connect(addr1).claimTokens();
         await expect(faucet.connect(addr1).claimTokens()).to.be.revertedWith(
            "Claim interval has not passed"
         );
      });

      it("Should reset the last claimed timestamp after claiming tokens", async function () {
         await network.provider.send("evm_increaseTime", [3600]); // Increase time by 1 hour
         await network.provider.send("evm_mine"); // Mine a new block

         await faucet.connect(addr1).claimTokens();

         await network.provider.send("evm_increaseTime", [3600]); // Increase time by another hour
         await network.provider.send("evm_mine"); // Mine a new block

         await expect(faucet.connect(addr1).claimTokens())
            .to.emit(faucet, "TokensClaimed")
            .withArgs(addr1.address, ethers.parseEther("100"));

         const addr1Balance = await token.balanceOf(addr1.address);
         expect(addr1Balance).to.equal(ethers.parseEther("200"));
      });
   });

   describe("Owner Functions", function () {
      it("Should allow owner to set claim amount", async function () {
         await faucet.setClaimAmount(ethers.parseEther("200"));
         expect(await faucet.claimAmount()).to.equal(ethers.parseEther("200"));
      });

      it("Should allow owner to set claim interval", async function () {
         await faucet.setClaimInterval(7200);
         expect(await faucet.claimInterval()).to.equal(7200);
      });

      it("Should allow owner to withdraw tokens", async function () {
         await faucet.withdrawTokens(ethers.parseEther("500"));
         const ownerBalance = await token.balanceOf(owner.address);
         expect(ownerBalance).to.equal(ethers.parseEther("600"));
      });

      it("Should allow owner to deposit tokens", async function () {
         await token.approve(faucet.target, ethers.parseEther("100"));
         await faucet.depositTokens(ethers.parseEther("100"));
         const faucetBalance = await token.balanceOf(faucet.target);
         expect(faucetBalance).to.equal(ethers.parseEther("1100"));
      });
   });
});
