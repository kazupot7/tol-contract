const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("BoardFactory", () => {
   let TOLToken, FundedToken, Ocean, Board, BoardFactory;
   let tolToken, fundedToken, ocean, boardFactory;
   let owner, addr1, addr2;
   const minBuy = ethers.parseEther("1");
   const maxBuy = ethers.parseEther("10");
   const rates = 1000;
   let deadline; // 1 day from now
   const targetRaised = ethers.parseEther("10");
   const rewardRatePerTOL = 10;
   const cid = "some-cid";
   const minimumTOLRequired = ethers.parseEther("1000");

   beforeEach(async () => {
      [owner, addr1, addr2] = await ethers.getSigners();
      deadline = Math.floor(Date.now() / 1000) + 60 * 60 * 24;

      TOLToken = await ethers.getContractFactory("TOLToken");
      FundedToken = await ethers.getContractFactory("TOLToken");
      Ocean = await ethers.getContractFactory("Ocean");
      BoardFactory = await ethers.getContractFactory("BoardFactory");

      tolToken = await TOLToken.deploy();
      fundedToken = await FundedToken.deploy();
      boardFactory = await BoardFactory.deploy(
         tolToken.target,
         minimumTOLRequired
      );
      ocean = await Ocean.deploy(
         boardFactory.target,
         tolToken.target,
         addr2.address
      );

      // Fund owner with initial tokens
      await tolToken.mint(owner.address, ethers.parseEther("100000"));
   });

   describe("BoardFactory", () => {
      it("Should create a new launchpad", async () => {
         await boardFactory.updateOceanInstance(ocean.target);
         const tx = await boardFactory.createLaunchpad(
            fundedToken.target,
            minBuy,
            maxBuy,
            rates,
            deadline,
            targetRaised,
            rewardRatePerTOL,
            cid
         );
         const filter = boardFactory.filters.LaunchpadCreated();
         const events = await boardFactory.queryFilter(filter);
         const launchpadAddress = events[0].args.launchpadAddress;

         expect(launchpadAddress).to.not.equal(ethers.ZeroAddress);
      });
   });

   describe("Board", () => {
      let board;
      beforeEach(async () => {
         // getting timestamp
         const blockNumBefore = await ethers.provider.getBlockNumber();
         const blockBefore = await ethers.provider.getBlock(blockNumBefore);
         deadline = blockBefore.timestamp + 60 * 60 * 24;

         await boardFactory.updateOceanInstance(ocean.target);
         const tx = await boardFactory.createLaunchpad(
            fundedToken.target,
            minBuy,
            maxBuy,
            rates,
            deadline,
            targetRaised,
            rewardRatePerTOL,
            cid
         );
         const filter = boardFactory.filters.LaunchpadCreated();
         const events = await boardFactory.queryFilter(filter);
         const launchpadAddress = events[0].args.launchpadAddress;

         board = await ethers.getContractAt("Board", launchpadAddress);

         await fundedToken.mint(
            launchpadAddress,
            ethers.parseEther("1000000000")
         );
         // await tolToken.approve(launchpadAddress, ethers.parseEther("1000"));
         // await board.placeTOL(ethers.parseEther("1000"));
      });

      it("Should allow buying presale", async () => {
         await tolToken.mint(addr1.address, ethers.parseEther("1000"));
         await tolToken
            .connect(addr1)
            .approve(board.target, ethers.parseEther("1000"));
         await board.connect(addr1).placeTOL(ethers.parseEther("1000"));
         await board
            .connect(addr1)
            .buyPresale({ value: ethers.parseEther("5") });

         const contribution = await board.getContribution(addr1.address);
         expect(contribution).to.equal(ethers.parseEther("5"));
      });

      it("Should allow token withdrawal after presale finalized", async () => {
         await tolToken.mint(addr1.address, ethers.parseEther("10000"));
         await tolToken
            .connect(addr1)
            .approve(board.target, ethers.parseEther("10000"));
         await board.connect(addr1).placeTOL(ethers.parseEther("10000"));
         await board
            .connect(addr1)
            .buyPresale({ value: ethers.parseEther("10") });

         // Mint funded tokens to the board for withdrawal
         await fundedToken.mint(board.target, ethers.parseEther("10000"));

         // Finalize the presale
         await network.provider.send("evm_increaseTime", [60 * 60 * 24 + 2]); // Move forward in time
         await board.finalizePresale();

         await board.connect(addr1).withdrawToken();
         const fundedBalance = await fundedToken.balanceOf(addr1.address);
         expect(fundedBalance).to.equal(ethers.parseEther("110000"));
      });

      it("Should allow refund if presale fails", async () => {
         await tolToken.mint(addr1.address, ethers.parseEther("1000"));
         await tolToken
            .connect(addr1)
            .approve(board.target, ethers.parseEther("1000"));
         await board.connect(addr1).placeTOL(ethers.parseEther("1000"));
         await board
            .connect(addr1)
            .buyPresale({ value: ethers.parseEther("5") });

         // Finalize the presale
         await network.provider.send("evm_increaseTime", [60 * 60 * 24 + 1]); // Move forward in time
         await board.finalizePresale();

         const initialBalance = await ethers.provider.getBalance(addr1.address);
         await board.connect(addr1).refund();
         const finalBalance = await ethers.provider.getBalance(addr1.address);
         expect(finalBalance).to.be.above(initialBalance);
      });

      it("Should allow emergency withdrawal during active presale", async () => {
         await tolToken.mint(addr1.address, ethers.parseEther("1000"));
         await tolToken
            .connect(addr1)
            .approve(board.target, ethers.parseEther("1000"));
         await board.connect(addr1).placeTOL(ethers.parseEther("1000"));
         await board
            .connect(addr1)
            .buyPresale({ value: ethers.parseEther("5") });

         const initialBalance = await ethers.provider.getBalance(addr1.address);
         await board.connect(addr1).emergencyWithdraw();
         const finalBalance = await ethers.provider.getBalance(addr1.address);
         expect(finalBalance).to.be.above(initialBalance);
      });
   });
});
