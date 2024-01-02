import { ethers } from "hardhat";
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import * as chai from 'chai';
import chaiAsPromised from 'chai-as-promised';
chai.use(chaiAsPromised);
import { Contract } from 'ethers';

function parseEther(amount: number) {
   return ethers.utils.parseEther(amount.toString());
}

function formatEther(amount: number) {
   return Number.parseFloat(ethers.utils.formatEther(amount));
}

enum State {
   Harvested,
   PurchasedByThirdParty,
   ShippedByFarmer,
   ReceivedByThirdParty,
   SoldByThirdParty,
   PurchasedByCustomer,
   ShippedByThirdParty,
   ReceivedByDeliveryHub,
   ShippedByDeliveryHub,
   ReceivedByCustomer
}

describe("--- SupplyChain", function () {
   let admin: SignerWithAddress,
      farmer: SignerWithAddress,
      thirdParty: SignerWithAddress,
      deliveryHub: SignerWithAddress,
      customer: SignerWithAddress;
   let supplyChain: Contract;
   let token: Contract;

   beforeEach(async () => {
      await ethers.provider.send("hardhat_reset", []); /* reset network hardhat  */
      [admin, farmer, thirdParty, deliveryHub, customer] = await ethers.getSigners();

      const TOKEN = await ethers.getContractFactory("AgriToken", admin);
      token = await TOKEN.deploy();
      const SupplyChain = await ethers.getContractFactory("SupplyChain", admin);
      supplyChain = await SupplyChain.deploy(admin.address, token.address);
   });

   /* positive testing */
   it("Create product in supply chain", async () => {
      await supplyChain.connect(admin).addFarmer(farmer.address);
      await supplyChain.connect(admin).addThirdParty(thirdParty.address);
      await supplyChain.connect(admin).addDeliveryHub(deliveryHub.address);
      await supplyChain.connect(customer).addCustomer(customer.address);
      await token.transfer(thirdParty.address, parseEther(10 ** 3));
      await token.transfer(customer.address, parseEther(10 ** 3));
      const balanceFarmer = formatEther(await token.balanceOf(farmer.address));
      const balanceThirdParty = formatEther(await token.balanceOf(thirdParty.address));
      const balanceDeliveryHub = formatEther(await token.balanceOf(deliveryHub.address));
      const balanceCustomer = formatEther(await token.balanceOf(customer.address));
      const balanceContract = formatEther(await token.balanceOf(supplyChain.address));
      console.log("address farmer:", farmer.address, "|", balanceFarmer);
      console.log("address thirdparty:", thirdParty.address, "|", balanceThirdParty);
      console.log("address delivery hub:", deliveryHub.address, "|", balanceDeliveryHub);
      console.log("address customer:", customer.address, "|", balanceCustomer);
      // -> Step 1 x
      await supplyChain.connect(farmer).harvestedProduct("Dâu tây", "dau", parseEther(30), "hoa qua", "http/farmer/image1", "dessdadcription", 50, "43242.43", "23432.432", "43.22", 78, "#codeFarmer");
      let product = await supplyChain.getProductByCode("dau");
      expect((await supplyChain.getProductCount()).toNumber()).equal(1);
      expect(await supplyChain.getProductState(product.uid)).equal(State.Harvested);
      // -> Step 2 x
      await token.connect(thirdParty).approve(supplyChain.address, product.productDetails.price);
      await supplyChain.connect(thirdParty).purchaseByThirdParty(product.uid, "#thirdpartycode");
      expect(formatEther(await token.balanceOf(thirdParty.address))).equal(balanceThirdParty - formatEther(product.productDetails.price));
      expect(formatEther(await token.balanceOf(supplyChain.address))).equal(balanceContract + formatEther(product.productDetails.price));
      expect(await supplyChain.getProductState(product.uid)).equal(State.PurchasedByThirdParty);
      // -> Step 3
      await supplyChain.connect(farmer).shipByFarmer(product.uid);
      expect(await supplyChain.getProductState(product.uid)).equal(State.ShippedByFarmer);
      // -> Step 4
      await supplyChain.connect(thirdParty).receiveByThirdParty(product.uid, "34.34", "423432.3242");
      product = await supplyChain.getProductByCode("dau"); // update infomation for product
      // after sell product -> balance of farmer + price product sell
      expect(formatEther(await token.balanceOf(farmer.address))).equal(balanceFarmer + formatEther(product.productDetails.price));
      console.log('balance of farmer after sell product: ', formatEther(await token.balanceOf(farmer.address)));
      // balance of contract will is 0
      expect(formatEther(await token.balanceOf(supplyChain.address))).equal(0);
      console.log("balance contract step 4 |", formatEther(await token.balanceOf(supplyChain.address)))
      expect(product.owner).equal(thirdParty.address);
      expect(await supplyChain.getProductState(product.uid)).equal(State.ReceivedByThirdParty);
      // -> Step 5
      await supplyChain.connect(thirdParty).sellByThirdParty(product.uid, parseEther(50));
      expect(await supplyChain.getProductState(product.uid)).equal(State.SoldByThirdParty);
      // -> Step 6 x
      product = await supplyChain.getProductByCode("dau");
      await token.connect(customer).approve(supplyChain.address, product.productDetails.priceThirdParty + parseEther(5));
      await supplyChain.connect(customer).purchaseByCustomer(product.uid, parseEther(5), 'Dien duong, dien ban, quang nam', "#customerCode");
      product = await supplyChain.getProductByCode("dau");
      expect(formatEther(await token.balanceOf(customer.address))).equal(balanceCustomer - formatEther(product.productDetails.priceThirdParty) - formatEther(product.customerDetails.feeShip));
      expect(formatEther(await token.balanceOf(supplyChain.address))).equal(balanceContract + formatEther(product.productDetails.priceThirdParty) + formatEther(product.customerDetails.feeShip));
      console.log("balance contract step 6 is 55 token |", formatEther(await token.balanceOf(supplyChain.address)));
      expect(await product.customerDetails.customer).equal(customer.address);
      expect(await supplyChain.getProductState(product.uid)).equal(State.PurchasedByCustomer);
      // -> Step 7 
      await supplyChain.connect(thirdParty).shipByThirdParty(product.uid);
      product = await supplyChain.getProductByCode("dau");
      expect(product.productState).equal(State.ShippedByThirdParty);
      // -> Step 8 x
      await supplyChain.connect(deliveryHub).receiveByDeliveryHub(product.uid, "443.4", "6765.332", "deliveryHubcode");
      product = await supplyChain.getProductByCode("dau");
      expect(product.owner).equal(deliveryHub.address);
      expect(product.productState).equal(State.ReceivedByDeliveryHub);
      // Step 9
      await supplyChain.connect(deliveryHub).shipByDeliveryHub(product.uid);
      product = await supplyChain.getProductByCode("dau");
      expect(product.productState).equal(State.ShippedByDeliveryHub);
      // Step 10
      const balanceThirdParty2 = formatEther(await token.balanceOf(thirdParty.address));
      await supplyChain.connect(customer).receiveByCustomer(product.uid);
      product = await supplyChain.getProductByCode("dau");
      expect(formatEther(await token.balanceOf(thirdParty.address))).equal(balanceThirdParty2 + formatEther(product.productDetails.priceThirdParty) - formatEther(product.productDetails.priceThirdParty) / 10);
      console.log("balance of third party step 10 is 1015 token | ", formatEther(await token.balanceOf(thirdParty.address)));
      expect(formatEther(await token.balanceOf(deliveryHub.address))).equal(balanceDeliveryHub + formatEther(product.customerDetails.feeShip) - formatEther(product.customerDetails.feeShip) / 10);
      console.log("balance delivery hub step 10 is 4.5 token |", formatEther(await token.balanceOf(deliveryHub.address)));
      console.log("balance contract step 10 is 5.5 token |", formatEther(await token.balanceOf(supplyChain.address)));
      console.log("balance customer step 10 is 945 |", formatEther(await token.balanceOf(customer.address)));
      expect(formatEther(await token.balanceOf(supplyChain.address))).equal(5.5);
      expect(product.owner).equal(customer.address);
      expect(product.productState).equal(State.ReceivedByCustomer);

      //->>>>> get data of product
      //console.log(await supplyChain.getProductByCode("dau"));
   });
   // negative testing
   it("Should not grant role, sender is not admin!", async () => {
      await expect(supplyChain.connect(farmer).addThirdParty(thirdParty.address)).revertedWith("Sender is not a admin");
   });
   it("Should not create product, Sender is not a farmer!", async () => {
      await expect(supplyChain.connect(farmer).harvestedProduct("Dâu tây", "dau", parseEther(30), "hoa qua", "http/farmer/image1", "dessdadcription", 50, "43242.43", "23432.432", "43.22", 78, "#codefarmer")).revertedWith("Sender is not a Farmer!");
   });
   it("Should buy product, Insufficient account balance", async () => {
      await supplyChain.connect(admin).addFarmer(farmer.address);
      await supplyChain.connect(admin).addThirdParty(thirdParty.address);
      await supplyChain.connect(farmer).harvestedProduct("Dâu tây", "dau", parseEther(30), "hoa qua", "http/farmer/image1", "dessdadcription", 50, "43242.43", "23432.432", "43.22", 78, "#codefarmer");
      let product = await supplyChain.getProductByCode("dau");
      await token.connect(thirdParty).approve(supplyChain.address, product.productDetails.price);
      await expect(supplyChain.connect(thirdParty).purchaseByThirdParty(1, "#codeTPT")).revertedWith("Insufficient account balance");
   })
});



