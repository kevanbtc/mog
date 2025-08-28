#!/usr/bin/env node

import hre from 'hardhat';
import dotenv from 'dotenv';

dotenv.config();

const ADMIN_ADDRESS = "0x8aced25DC8530FDaf0f86D53a0A1E02AAfA7Ac7A";
const TREASURY_ADDRESS = "0x8aced25DC8530FDaf0f86D53a0A1E02AAfA7Ac7A";

async function main() {
    console.log("🚀 Deploying Settlement + Affiliate System to Polygon...");
    console.log(`Admin: ${ADMIN_ADDRESS}`);
    console.log(`Treasury: ${TREASURY_ADDRESS}`);
    
    // Get the contract factory
    const AtomicSettlementBus = await hre.ethers.getContractFactory("AtomicSettlementBus");
    
    // Estimate gas
    const gasEstimate = await AtomicSettlementBus.signer.estimateGas(
        AtomicSettlementBus.getDeployTransaction(ADMIN_ADDRESS, TREASURY_ADDRESS)
    );
    console.log(`Estimated gas: ${gasEstimate.toLocaleString()}`);
    
    // Deploy with extra gas buffer
    const adjustedGas = Math.floor(Number(gasEstimate) * 1.3);
    console.log(`Deploying with gas limit: ${adjustedGas.toLocaleString()}`);
    
    const settlement = await AtomicSettlementBus.deploy(ADMIN_ADDRESS, TREASURY_ADDRESS, {
        gasLimit: adjustedGas
    });
    
    console.log("⏳ Waiting for deployment confirmation...");
    const deployedContract = await settlement.waitForDeployment();
    const address = await deployedContract.getAddress();
    
    const receipt = await settlement.deploymentTransaction().wait();
    
    console.log("✅ AtomicSettlementBus deployed successfully!");
    console.log(`📍 Contract Address: ${address}`);
    console.log(`🏗️  Transaction Hash: ${receipt.hash}`);
    console.log(`⛽ Gas Used: ${receipt.gasUsed.toLocaleString()}`);
    console.log(`🏷️  Block Number: ${receipt.blockNumber}`);
    console.log(`🔗 Polygonscan: https://polygonscan.com/address/${address}`);
    
    // Add supported registries (if we have the addresses)
    console.log("\n🔧 Configuring settlement bus...");
    
    try {
        // Add DigitalGiantRegistry
        if (process.env.DIGITALGIANT_REGISTRY_ADDRESS) {
            const tx1 = await deployedContract.addRegistry(
                process.env.DIGITALGIANT_REGISTRY_ADDRESS,
                "DigitalGiantRegistry"
            );
            await tx1.wait();
            console.log("✅ Added DigitalGiantRegistry");
        }
        
        // Register default affiliate (admin as first affiliate)
        const tx2 = await deployedContract.registerAffiliate(ADMIN_ADDRESS, 500); // 5%
        await tx2.wait();
        console.log("✅ Registered admin as affiliate (5% commission)");
        
        console.log("\n🎉 Settlement bus fully configured!");
        
    } catch (error) {
        console.log("⚠️  Configuration skipped (contracts not yet deployed)");
        console.log("   Run after deploying TLD contracts to add registries");
    }
    
    // Output environment variable format
    console.log("\n📝 Add to your .env file:");
    console.log(`ATOMIC_SETTLEMENT_BUS_ADDRESS=${address}`);
    console.log(`NEXT_PUBLIC_SETTLEMENT_BUS=${address}`);
    
    console.log("\n🎯 Deploying AffiliateRegistry...");
    
    // Deploy AffiliateRegistry
    const AffiliateRegistry = await hre.ethers.getContractFactory("AffiliateRegistry");
    const affiliateGasEstimate = await AffiliateRegistry.signer.estimateGas(
        AffiliateRegistry.getDeployTransaction(ADMIN_ADDRESS)
    );
    const affiliateGas = Math.floor(Number(affiliateGasEstimate) * 1.3);
    
    const affiliateRegistry = await AffiliateRegistry.deploy(ADMIN_ADDRESS, {
        gasLimit: affiliateGas
    });
    
    console.log("⏳ Waiting for AffiliateRegistry deployment...");
    const deployedAffiliate = await affiliateRegistry.waitForDeployment();
    const affiliateAddress = await deployedAffiliate.getAddress();
    
    const affiliateReceipt = await affiliateRegistry.deploymentTransaction().wait();
    
    console.log("✅ AffiliateRegistry deployed successfully!");
    console.log(`📍 Contract Address: ${affiliateAddress}`);
    console.log(`🏗️  Transaction Hash: ${affiliateReceipt.hash}`);
    console.log(`🔗 Polygonscan: https://polygonscan.com/address/${affiliateAddress}`);
    
    // Output all environment variables
    console.log("\n📝 Add to your .env file:");
    console.log(`ATOMIC_SETTLEMENT_BUS_ADDRESS=${address}`);
    console.log(`AFFILIATE_REGISTRY_ADDRESS=${affiliateAddress}`);
    console.log(`NEXT_PUBLIC_SETTLEMENT_BUS=${address}`);
    console.log(`NEXT_PUBLIC_AFFILIATE_REGISTRY=${affiliateAddress}`);
    
    console.log("\n🚀 Ready for stablecoin payments and affiliate program!");
    console.log("\n💰 System now supports:");
    console.log("   • USDC/USDT payments");
    console.log("   • 5-10% affiliate commissions");
    console.log("   • Automatic tier upgrades");
    console.log("   • Real-time commission tracking");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });