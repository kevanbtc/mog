import hre from "hardhat";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("🚀 Deploying Digital Giant x MOG stack with:", deployer.address);
  console.log("Balance:", hre.ethers.formatEther(await hre.ethers.provider.getBalance(deployer.address)));

  // Deploy Digital Giant Registry
  console.log("\n📝 Deploying DigitalGiantRegistry...");
  const DGNS = await hre.ethers.getContractFactory("DigitalGiantRegistry");
  const registry = await DGNS.deploy(deployer.address);
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  console.log("✅ DigitalGiantRegistry deployed at:", registryAddress);

  // Deploy VaultProofNFT compliance layer
  console.log("\n🛡️ Deploying VaultProofNFT compliance layer...");
  const VaultProof = await hre.ethers.getContractFactory("VaultProofNFT");
  const vaultProof = await VaultProof.deploy(deployer.address);
  await vaultProof.waitForDeployment();
  const vaultProofAddress = await vaultProof.getAddress();
  console.log("✅ VaultProofNFT deployed at:", vaultProofAddress);

  // Set deployer as authorized verifier for compliance
  console.log("\n🔐 Authorizing deployer as compliance verifier...");
  const authTx = await vaultProof.setAuthorizedVerifier(deployer.address, true);
  await authTx.wait();
  console.log("✅ Deployer authorized as verifier");

  console.log("\n🎉 Digital Giant x MOG deployment complete!");
  console.log("═══════════════════════════════════════════");
  console.log("📋 Contract Addresses:");
  console.log("DigitalGiantRegistry:", registryAddress);
  console.log("VaultProofNFT:       ", vaultProofAddress);
  console.log("═══════════════════════════════════════════");
  console.log("🔗 Next steps:");
  console.log("1. Verify contracts on Polygonscan");
  console.log("2. Set up IPFS/Pinata integration");
  console.log("3. Deploy frontend portal");
  console.log("4. Configure domain resolution");

  return {
    registry: registryAddress,
    vaultProof: vaultProofAddress
  };
}

main().catch((err) => {
  console.error("❌ Deployment failed:", err);
  process.exitCode = 1;
});
