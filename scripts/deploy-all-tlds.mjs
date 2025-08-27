#!/usr/bin/env node

import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

const require = createRequire(import.meta.url);
const execAsync = promisify(exec);

// Load environment variables
import dotenv from 'dotenv';
dotenv.config();

const ADMIN_ADDRESS = "0x8aced25DC8530FDaf0f86D53a0A1E02AAfA7Ac7A";
const NETWORK = "polygon";

// TLD contract deployment configuration
const TLD_CONFIGS = [
    {
        name: "GoldTLD",
        file: "GoldTLD.sol",
        constructor: [ADMIN_ADDRESS],
        description: "Precious metals domain registry with commodity backing"
    },
    {
        name: "OilTLD", 
        file: "OilTLD.sol",
        constructor: [ADMIN_ADDRESS],
        description: "Energy sector domain registry with production tracking"
    },
    {
        name: "BankTLD",
        file: "BankTLD.sol", 
        constructor: [ADMIN_ADDRESS],
        description: "Banking sector registry with SWIFT integration"
    },
    {
        name: "RealTLD",
        file: "RealTLD.sol",
        constructor: [ADMIN_ADDRESS], 
        description: "Real estate registry with RWA tokenization"
    },
    {
        name: "UsdTLD",
        file: "UsdTLD.sol",
        constructor: [ADMIN_ADDRESS],
        description: "Currency/DeFi registry with compliance integration"
    }
];

class TLDDeployer {
    constructor() {
        this.deploymentResults = [];
        this.startTime = Date.now();
        this.gasUsed = 0n;
        this.totalCost = 0n;
    }

    async deploy() {
        console.log("🚀 DIGITAL GIANT TLD MASS DEPLOYMENT");
        console.log("=====================================");
        console.log(`Network: ${NETWORK.toUpperCase()}`);
        console.log(`Admin Address: ${ADMIN_ADDRESS}`);
        console.log(`Timestamp: ${new Date().toISOString()}`);
        console.log(`Deploying ${TLD_CONFIGS.length} TLD contracts...\n`);

        // Compile all contracts first
        await this.compileContracts();

        // Deploy each TLD contract
        for (let i = 0; i < TLD_CONFIGS.length; i++) {
            const config = TLD_CONFIGS[i];
            console.log(`📋 [${i + 1}/${TLD_CONFIGS.length}] Deploying ${config.name}...`);
            
            try {
                const result = await this.deployContract(config);
                this.deploymentResults.push(result);
                console.log(`✅ ${config.name} deployed successfully!`);
                console.log(`   Address: ${result.address}`);
                console.log(`   Gas Used: ${result.gasUsed.toLocaleString()}`);
                console.log(`   Transaction: ${result.transactionHash}\n`);
                
                // Brief delay to avoid rate limiting
                await this.delay(2000);
                
            } catch (error) {
                console.error(`❌ Failed to deploy ${config.name}:`, error.message);
                
                // Retry once with higher gas
                console.log(`🔄 Retrying ${config.name} with increased gas...`);
                try {
                    const retryResult = await this.deployContract(config, true);
                    this.deploymentResults.push(retryResult);
                    console.log(`✅ ${config.name} deployed on retry!`);
                    console.log(`   Address: ${retryResult.address}\n`);
                } catch (retryError) {
                    console.error(`💥 Final failure for ${config.name}:`, retryError.message);
                    this.deploymentResults.push({
                        name: config.name,
                        success: false,
                        error: retryError.message
                    });
                }
            }
        }

        // Generate comprehensive deployment report
        await this.generateDeploymentReport();
        await this.updateEnvironmentFile();
        
        console.log("🎉 TLD DEPLOYMENT SEQUENCE COMPLETE!");
        this.printFinalSummary();
    }

    async compileContracts() {
        console.log("🔧 Compiling all TLD contracts...");
        try {
            const { stdout, stderr } = await execAsync('HARDHAT_CONFIG=./hardhat.config.mjs npx hardhat compile');
            if (stderr) console.log("Compile warnings:", stderr);
            console.log("✅ All contracts compiled successfully!\n");
        } catch (error) {
            console.error("❌ Compilation failed:", error.message);
            throw error;
        }
    }

    async deployContract(config, isRetry = false) {
        const deployScript = this.generateDeployScript(config, isRetry);
        const scriptPath = `/tmp/deploy_${config.name}.mjs`;
        
        // Write temporary deployment script
        fs.writeFileSync(scriptPath, deployScript);
        
        try {
            const { stdout, stderr } = await execAsync(
                `cd /Users/kevanb/digital-giant-domains && HARDHAT_CONFIG=./hardhat.config.mjs node ${scriptPath}`
            );
            
            if (stderr) console.log("Deploy warnings:", stderr);
            
            // Parse deployment result from stdout
            const result = this.parseDeploymentOutput(stdout, config.name);
            
            // Clean up temp script
            fs.unlinkSync(scriptPath);
            
            return result;
            
        } catch (error) {
            // Clean up temp script on error
            if (fs.existsSync(scriptPath)) {
                fs.unlinkSync(scriptPath);
            }
            throw error;
        }
    }

    generateDeployScript(config, isRetry = false) {
        const gasMultiplier = isRetry ? 1.5 : 1.2;
        
        return `
import hre from 'hardhat';

async function main() {
    console.log("Deploying ${config.name} to ${NETWORK}...");
    
    const ContractFactory = await hre.ethers.getContractFactory("${config.name}");
    
    const gasEstimate = await ContractFactory.signer.estimateGas(
        ContractFactory.getDeployTransaction(...${JSON.stringify(config.constructor)})
    );
    
    const adjustedGas = Math.floor(Number(gasEstimate) * ${gasMultiplier});
    
    const contract = await ContractFactory.deploy(...${JSON.stringify(config.constructor)}, {
        gasLimit: adjustedGas
    });
    
    console.log("Waiting for deployment confirmation...");
    const deployedContract = await contract.waitForDeployment();
    const receipt = await deployedContract.deploymentTransaction().wait();
    
    console.log("DEPLOYMENT_RESULT_START");
    console.log(JSON.stringify({
        name: "${config.name}",
        address: await deployedContract.getAddress(),
        transactionHash: receipt.hash,
        gasUsed: receipt.gasUsed.toString(),
        blockNumber: receipt.blockNumber,
        success: true
    }));
    console.log("DEPLOYMENT_RESULT_END");
}

main().catch(console.error);
`;
    }

    parseDeploymentOutput(stdout, contractName) {
        const startMarker = "DEPLOYMENT_RESULT_START";
        const endMarker = "DEPLOYMENT_RESULT_END";
        
        const startIndex = stdout.indexOf(startMarker);
        const endIndex = stdout.indexOf(endMarker);
        
        if (startIndex === -1 || endIndex === -1) {
            throw new Error("Could not parse deployment result");
        }
        
        const resultJson = stdout.substring(startIndex + startMarker.length, endIndex).trim();
        const result = JSON.parse(resultJson);
        
        // Convert gas used to BigInt for accumulation
        result.gasUsed = BigInt(result.gasUsed);
        this.gasUsed += result.gasUsed;
        
        return result;
    }

    async generateDeploymentReport() {
        const reportPath = 'TLD_DEPLOYMENT_REPORT.md';
        const successfulDeployments = this.deploymentResults.filter(r => r.success);
        const failedDeployments = this.deploymentResults.filter(r => !r.success);
        
        const report = `# 🚀 TLD MASS DEPLOYMENT REPORT

## Deployment Summary
**Date**: ${new Date().toISOString()}
**Network**: ${NETWORK.toUpperCase()}
**Admin Address**: ${ADMIN_ADDRESS}
**Total Deployments**: ${this.deploymentResults.length}
**Successful**: ${successfulDeployments.length}
**Failed**: ${failedDeployments.length}
**Total Gas Used**: ${this.gasUsed.toLocaleString()}

---

## ✅ Successful Deployments

${successfulDeployments.map(result => `
### ${result.name}
- **Contract Address**: \`${result.address}\`
- **Transaction Hash**: \`${result.transactionHash}\`
- **Gas Used**: ${result.gasUsed.toLocaleString()}
- **Block Number**: ${result.blockNumber}
- **Polygonscan**: [View Contract](https://polygonscan.com/address/${result.address})
- **Status**: ✅ **LIVE**
`).join('\n')}

---

## Contract Addresses Summary

| TLD Contract | Address | Status |
|-------------|---------|---------|
${successfulDeployments.map(r => `| **${r.name}** | \`${r.address}\` | ✅ LIVE |`).join('\n')}

---

## Failed Deployments

${failedDeployments.length > 0 ? failedDeployments.map(result => `
### ${result.name}
- **Error**: ${result.error}
- **Status**: ❌ **FAILED**
`).join('\n') : 'None - All deployments successful! 🎉'}

---

## Next Steps

1. **Frontend Integration**: Update portal with new TLD contracts
2. **Subdomain Factory**: Deploy batch minting system
3. **Enterprise APIs**: Build integration endpoints
4. **Marketing Launch**: Begin enterprise outreach campaigns
5. **Compliance Setup**: Configure regulatory verifiers

---

## Environment Variables

Add these to your .env file:

\`\`\`
${successfulDeployments.map(r => `${r.name.toUpperCase()}_ADDRESS=${r.address}`).join('\n')}
\`\`\`

---

## Usage Examples

### GoldTLD
\`\`\`javascript
const goldTLD = await ethers.getContractAt("GoldTLD", "${successfulDeployments.find(r => r.name === 'GoldTLD')?.address || 'DEPLOY_FIRST'}");
await goldTLD.mintGoldDomain(to, "goldcorp", ipfsCID, 2, 1000, "Fort Knox");
\`\`\`

### BankTLD  
\`\`\`javascript
const bankTLD = await ethers.getContractAt("BankTLD", "${successfulDeployments.find(r => r.name === 'BankTLD')?.address || 'DEPLOY_FIRST'}");
await bankTLD.mintBankDomain(to, "jpmorgan", ipfsCID, 1, 2, "MSB123", "USA,UK", 1000000000, swiftBIC);
\`\`\`

---

*Deployment completed in ${Math.round((Date.now() - this.startTime) / 1000)} seconds*
*Generated by Digital Giant TLD Deployer*
`;

        fs.writeFileSync(reportPath, report);
        console.log(`📄 Deployment report generated: ${reportPath}`);
    }

    async updateEnvironmentFile() {
        const envPath = '.env';
        let envContent = '';
        
        // Read existing .env if it exists
        if (fs.existsSync(envPath)) {
            envContent = fs.readFileSync(envPath, 'utf8');
        }
        
        // Add new contract addresses
        const successfulDeployments = this.deploymentResults.filter(r => r.success);
        const newEnvVars = successfulDeployments.map(result => 
            `${result.name.toUpperCase()}_ADDRESS=${result.address}`
        ).join('\n');
        
        if (newEnvVars) {
            envContent += '\n\n# TLD Contract Addresses\n' + newEnvVars + '\n';
            fs.writeFileSync(envPath, envContent);
            console.log(`🔧 Environment file updated with ${successfulDeployments.length} contract addresses`);
        }
    }

    printFinalSummary() {
        const successful = this.deploymentResults.filter(r => r.success).length;
        const total = this.deploymentResults.length;
        const duration = Math.round((Date.now() - this.startTime) / 1000);
        
        console.log("\n" + "=".repeat(60));
        console.log("🏆 FINAL DEPLOYMENT SUMMARY");
        console.log("=".repeat(60));
        console.log(`✅ Success Rate: ${successful}/${total} (${Math.round(successful/total*100)}%)`);
        console.log(`⏱️  Total Time: ${duration} seconds`);
        console.log(`⛽ Total Gas Used: ${this.gasUsed.toLocaleString()}`);
        console.log(`🌐 Network: ${NETWORK.toUpperCase()}`);
        
        if (successful === total) {
            console.log("\n🎉 ALL TLD CONTRACTS DEPLOYED SUCCESSFULLY!");
            console.log("🚀 Ready for enterprise client onboarding!");
            console.log("💰 Revenue target: $100K+ within 30 days");
        } else {
            console.log(`\n⚠️  ${total - successful} deployments failed - review errors above`);
        }
        
        console.log("\n📋 Next Actions:");
        console.log("1. Review TLD_DEPLOYMENT_REPORT.md");
        console.log("2. Update frontend with new contract addresses");  
        console.log("3. Deploy SubdomainFactory for batch operations");
        console.log("4. Begin enterprise outreach campaigns");
        console.log("5. Set up regulatory verifier accounts");
        
        console.log("\n🔗 Contract verification:");
        this.deploymentResults.filter(r => r.success).forEach(result => {
            console.log(`   ${result.name}: https://polygonscan.com/address/${result.address}`);
        });
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Execute deployment
const deployer = new TLDDeployer();
deployer.deploy().catch(console.error);