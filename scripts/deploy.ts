import { ethers, hardhatArguments } from 'hardhat';
import * as Config from './config';

async function main() {
   await Config.initConfig();
   const network = hardhatArguments.network ?? 'dev';
   const [deployer] = await ethers.getSigners();
   console.log('deploy from address: ', deployer.address);

   // const AgiToken = await ethers.getContractFactory("AgriToken");
   // const agriToken = await AgiToken.deploy();
   // console.log("AgriToken address: ", agriToken.address);
   // Config.setConfig(network + '.AgriToken', agriToken.address);

   // const Ico = await ethers.getContractFactory("AGTCrowdSale");
   // const ico = await Ico.deploy(1000, '0xcCBF9BcaAbeaE9d0F382695d6fFe31c39E533F17', '0x016C31223Bdb9454E277A042A924C37BBafe1E18')
   // console.log("ICO address: ", ico.address);
   // Config.setConfig(network + '.Ico', ico.address);

   const SupplyChain = await ethers.getContractFactory("SupplyChain");
   const supplyChain = await SupplyChain.deploy('0xcCBF9BcaAbeaE9d0F382695d6fFe31c39E533F17', '0x016C31223Bdb9454E277A042A924C37BBafe1E18');
   console.log("Supplychain address: ", supplyChain.address);
   Config.setConfig(network + '.SupplyChain', supplyChain.address);

   await Config.updateConfig()
}

main()
   .then(() => process.exit(0))
   .catch(error => {
      console.log(error);
      process.exit(1)
   })