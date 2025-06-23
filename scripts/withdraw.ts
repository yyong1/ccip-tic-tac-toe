import { ethers } from "hardhat";

async function main() {
  const CONTRACT_ADDRESS = "0x6A00077dE2b56d8E488F765fea3Eee002DA202eb";
  const BENEFICIARY_ADDRESS = "0x42e442806Cc79113D9Df994B085C1b6585d65661";
  const [owner] = await ethers.getSigners();
  const contract = await ethers.getContractAt(
    "TTTDemo",
    CONTRACT_ADDRESS,
    owner
  );

  // Check owner
  const contractOwner = await contract.owner();
  const signerAddress = await owner.getAddress();
  console.log("Contract owner:", contractOwner);
  console.log("Your signer address:", signerAddress);

  if (contractOwner.toLowerCase() !== signerAddress.toLowerCase()) {
    throw new Error("You are NOT the owner! Withdraw will fail.");
  }

  // Check contract balance
  const balanceBefore = await ethers.provider.getBalance(CONTRACT_ADDRESS);
  console.log(
    "Contract balance before:",
    ethers.utils.formatEther(balanceBefore)
  );

  // Attempt withdraw
  const tx = await contract.withdraw(BENEFICIARY_ADDRESS);
  console.log(`Transaction sent: ${tx.hash}`);
  const receipt = await tx.wait();
  console.log("Withdraw tx receipt:", receipt);

  // Check contract balance after
  const balanceAfter = await ethers.provider.getBalance(CONTRACT_ADDRESS);
  console.log(
    "Contract balance after:",
    ethers.utils.formatEther(balanceAfter)
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
