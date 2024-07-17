const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Ocean", function () {
   let Ocean, ocean, TOLToken, tolToken, owner, addr1, addr2;

   beforeEach(async function () {
      [owner, addr1, addr2] = await ethers.getSigners();

      // Deploy mock TOLToken
      const TOLToken = await ethers.getContractFactory("TOLToken");
      tolToken = await TOLToken.deploy();

      // Deploy Ocean contract
      const Ocean = await ethers.getContractFactory("Ocean");
      ocean = await Ocean.deploy(addr1.address, tolToken.target, addr2.address);

      await ocean
         .connect(addr1)
         .storeProject(addr2.address, addr2.address, "QmCID");
   });

   describe("Project Management", function () {
      it("Should store a new project", async function () {
         const project = await ocean.projects(1);
         expect(project.owner).to.equal(addr2.address);
         expect(project.contractAddress).to.equal(addr2.address);
         expect(project.cid).to.equal("QmCID");
      });

      it("Should update the CID of an existing project", async function () {
         await ocean.connect(addr2).updateProject(1, "QmNewCID");
         const project = await ocean.projects(1);
         expect(project.cid).to.equal("QmNewCID");
      });

      it("Should terminate a project", async function () {
         await ocean.terminateProject(1);
         const project = await ocean.projects(1);
         expect(project.isTerminated).to.be.true;
      });

      it("Should boost a project", async function () {
         await ocean.setBoostRate(2);
         await tolToken.mint(owner.address, ethers.parseEther("100"));
         await tolToken.transfer(addr2.address, ethers.parseEther("10"));
         await tolToken
            .connect(addr2)
            .approve(ocean.target, ethers.parseEther("10"));
         await ocean.connect(addr2).boostProject(1, ethers.parseEther("10"));
         const project = await ocean.projects(1);
         expect(project.boostPoint).to.equal(5);
      });

      it("Should verify and update the certification status of a project", async function () {
         const abiCoder = new ethers.AbiCoder();
         const input = abiCoder.encode(["uint256", "bool"], [1, true]);
         await ocean.verify(input);
         const project = await ocean.projects(1);
         expect(project.isCertified).to.be.true;
      });
   });

   describe("Access Control", function () {
      it("Should only allow the factory to store projects", async function () {
         await expect(
            ocean.storeProject(addr2.address, addr2.address, "QmCID")
         ).to.be.revertedWith("Only the factory can call this function");
      });

      it("Should only allow the project owner to update the project CID", async function () {
         await expect(
            ocean.connect(addr1).updateProject(1, "QmNewCID")
         ).to.be.revertedWith("Only the project owner can call this function");
      });

      it("Should only allow the owner to terminate projects", async function () {
         await expect(
            ocean.connect(addr2).terminateProject(1)
         ).to.be.revertedWith("Ownable: caller is not the owner");
      });
   });
});
