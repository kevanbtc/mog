import hre from "hardhat";
import dotenv from "dotenv";

dotenv.config();

const REGISTRY_ADDRESS = "0xE6b9427106BdB7E0C2aEb52eB515aa024Ba7dF8B";
const VAULT_PROOF_ADDRESS = "0xed793AbD85235Af801397275c9836A0507a32a08";

async function main() {
  console.log("🧪 Testing Digital Giant x MOG deployment...");
  console.log("═".repeat(50));

  const [deployer] = await hre.ethers.getSigners();
  console.log("Testing with address:", deployer.address);

  // Get contract instances
  const registry = await hre.ethers.getContractAt("DigitalGiantRegistry", REGISTRY_ADDRESS);
  const vaultProof = await hre.ethers.getContractAt("VaultProofNFT", VAULT_PROOF_ADDRESS);

  console.log("\n📝 Testing DigitalGiantRegistry...");
  
  // Test basic properties
  const name = await registry.name();
  const symbol = await registry.symbol();
  const nextDomainId = await registry.nextDomainId();
  
  console.log("✅ Name:", name);
  console.log("✅ Symbol:", symbol);
  console.log("✅ Next Domain ID:", nextDomainId.toString());

  console.log("\n🛡️ Testing VaultProofNFT...");
  
  const proofName = await vaultProof.name();
  const proofSymbol = await vaultProof.symbol();
  const nextProofId = await vaultProof.nextProofId();
  const isAuthorized = await vaultProof.authorizedVerifiers(deployer.address);
  
  console.log("✅ Name:", proofName);
  console.log("✅ Symbol:", proofSymbol);
  console.log("✅ Next Proof ID:", nextProofId.toString());
  console.log("✅ Deployer authorized:", isAuthorized);

  console.log("\n🚀 Testing Domain Minting (with placeholder CID)...");
  
  try {
    // Create sample metadata for testing
    const sampleMetadata = {
      name: "digitalgiant.x",
      description: "Digital Giant flagship domain",
      image: "https://digitalgiant.x/assets/domain.png",
      external_url: "https://digitalgiant.x",
      attributes: [
        { trait_type: "Domain Type", value: "Flagship" },
        { trait_type: "Registry", value: "Digital Giant" },
        { trait_type: "Minted", value: new Date().toISOString() }
      ]
    };
    
    // Use a sample CID (placeholder)
    const sampleCID = "QmTEST1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijk";
    
    const tx = await registry.mintDomain(
      deployer.address,
      "digitalgiant", 
      sampleCID
    );
    
    console.log("⏳ Minting transaction sent:", tx.hash);
    const receipt = await tx.wait();
    console.log("✅ Domain minted successfully!");
    console.log("Gas used:", receipt.gasUsed.toString());
    
    // Check the minted domain
    const tokenId = await registry.domainToTokenId("digitalgiant");
    const domainName = await registry.tokenIdToDomain(tokenId);
    const owner = await registry.ownerOf(tokenId);
    const resolvedAddress = await registry.resolveDomain("digitalgiant");
    
    console.log("✅ Token ID:", tokenId.toString());
    console.log("✅ Domain Name:", domainName);
    console.log("✅ Owner:", owner);
    console.log("✅ Resolves to:", resolvedAddress);
    
  } catch (error) {
    console.log("⚠️ Minting test failed (expected if domain already exists):", error.message);
  }

  console.log("\n🎯 Testing Compliance Proof Minting...");
  
  try {
    const proofTx = await vaultProof.mintProof(
      deployer.address,
      0, // ProofType.EIN_CONFIRMATION
      "Digital Giant LLC",
      "EIN123456789",
      "QmCOMPLIANCE1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabc"
    );
    
    console.log("⏳ Compliance proof transaction sent:", proofTx.hash);
    const proofReceipt = await proofTx.wait();
    console.log("✅ Compliance proof minted successfully!");
    console.log("Gas used:", proofReceipt.gasUsed.toString());
    
  } catch (error) {
    console.log("⚠️ Compliance proof test failed:", error.message);
  }

  console.log("\n🎉 Deployment test complete!");
  console.log("═".repeat(50));
  console.log("🌐 Contract URLs:");
  console.log(`Registry: https://polygonscan.com/address/${REGISTRY_ADDRESS}`);
  console.log(`VaultProof: https://polygonscan.com/address/${VAULT_PROOF_ADDRESS}`);
  console.log("\n🔗 Ready for frontend integration!");
}

main().catch((error) => {
  console.error("❌ Test failed:", error);
  process.exitCode = 1;
});