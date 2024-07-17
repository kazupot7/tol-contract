const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TOLToken", () => {
   let TOLToken, token, owner, addr1, addr2;

   beforeEach(async () => {
      [owner, addr1, addr2] = await ethers.getSigners();
      TOLToken = await ethers.getContractFactory("TOLToken");
      token = await TOLToken.deploy();
   });

   describe("Deployment", () => {
      it("Should assign the total supply of tokens to the owner", async () => {
         const ownerBalance = await token.balanceOf(owner.address);
         expect(await token.totalSupply()).to.equal(ownerBalance);
      });
   });

   describe("Transactions", () => {
      it("Should transfer tokens between accounts", async () => {
         // Transfer 50 tokens from owner to addr1
         await token.mint(owner.address, "50");
         await token.transfer(addr1.address, 50);
         const addr1Balance = await token.balanceOf(addr1.address);
         expect(addr1Balance).to.equal(50);

         // Transfer 50 tokens from addr1 to addr2
         await token.connect(addr1).transfer(addr2.address, 50);
         const addr2Balance = await token.balanceOf(addr2.address);
         expect(addr2Balance).to.equal(50);
      });

      it("Should fail if sender doesn't have enough tokens", async () => {
         const initialOwnerBalance = await token.balanceOf(owner.address);

         // Try to send 1 token from addr1 (0 tokens) to owner (should fail)
         await expect(
            token.connect(addr1).transfer(owner.address, 1)
         ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

         // Owner balance shouldn't have changed.
         expect(await token.balanceOf(owner.address)).to.equal(
            initialOwnerBalance
         );
      });
   });

   describe("Minting", () => {
      it("Should allow owner to mint new tokens", async () => {
         await token.mint(owner.address, BigInt(100 * 10 ** 18).toString());
         const ownerBalance = await token.balanceOf(owner.address);
         expect(ownerBalance).to.equal(BigInt(100 * 10 ** 18));
      });

      it("Should not allow non-owner to mint tokens", async () => {
         await expect(
            token.connect(addr1).mint(addr1.address, 100)
         ).to.be.revertedWith("Ownable: caller is not the owner");
      });
   });

   describe("Minimum Holding Time", () => {
      it("Should set the minimum holding time by the owner", async () => {
         await token.setMinimumHoldingTime(3600); // Set to 1 hour
         const holdingTime = await token.minimumHoldingTime();
         expect(holdingTime).to.equal(3600);
      });

      it("Should not allow non-owner to set the minimum holding time", async () => {
         await expect(
            token.connect(addr1).setMinimumHoldingTime(3600)
         ).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it("Should return the correct minimum holding time", async () => {
         await token.setMinimumHoldingTime(3600); // Set to 1 hour
         const holdingTime = await token.minimumHoldingTime();
         expect(holdingTime).to.equal(3600);
      });
   });

   describe("Holding Time", () => {
      it("Should return the correct holding time for an account", async () => {
         // Mint tokens to addr1
         await token.mint(owner.address, 100);
         await token.transfer(addr2.address, 50);
         // Fast forward time by 1 hour (3600 seconds)
         await ethers.provider.send("evm_increaseTime", [3600]);
         await ethers.provider.send("evm_mine");

         const holdingTime = await token.getHoldingTime(addr2.address);
         expect(holdingTime).to.be.closeTo(3600, 2); // Allow for a small margin of error
      });

      it("Should return zero holding time if tokens have not been held", async () => {
         const holdingTime = await token.getHoldingTime(addr1.address);
         expect(holdingTime).to.equal(0);
      });
   });
});
