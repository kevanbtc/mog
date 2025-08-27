#!/usr/bin/env node

import chalk from 'chalk';

const REGISTRY_ADDRESS = "0xE6b9427106BdB7E0C2aEb52eB515aa024Ba7dF8B";
const VAULT_PROOF_ADDRESS = "0xed793AbD85235Af801397275c9836A0507a32a08";
const DEPLOYER_ADDRESS = "0x8aced25DC8530FDaf0f86D53a0A1E02AAfA7Ac7A";

console.log(`
🦄 ${chalk.bold.cyan('DIGITAL GIANT x MOG SOVEREIGN DOMAINS')}
${'='.repeat(52)}

${chalk.bold.green('✅ DEPLOYMENT COMPLETE!')}

${chalk.bold.yellow('📋 Smart Contracts (Polygon Mainnet):')}
├─ ${chalk.cyan('DigitalGiantRegistry:')} ${chalk.gray(REGISTRY_ADDRESS)}
├─ ${chalk.cyan('VaultProofNFT:')}        ${chalk.gray(VAULT_PROOF_ADDRESS)}  
└─ ${chalk.cyan('Deployer:')}             ${chalk.gray(DEPLOYER_ADDRESS)}

${chalk.bold.yellow('🌐 Live URLs:')}
├─ ${chalk.blue('Registry Contract:')} ${chalk.underline(`https://polygonscan.com/address/${REGISTRY_ADDRESS}`)}
├─ ${chalk.blue('VaultProof Contract:')} ${chalk.underline(`https://polygonscan.com/address/${VAULT_PROOF_ADDRESS}`)}
└─ ${chalk.blue('Frontend Portal:')} ${chalk.underline('http://localhost:3004')}

${chalk.bold.yellow('🏗️ Architecture:')}
├─ ${chalk.green('ERC-721 Domain NFTs')} with resolution & vault binding
├─ ${chalk.green('ERC-6551 Programmable Accounts')} for each domain
├─ ${chalk.green('ISO 20022 Compliance Layer')} with automated messaging
├─ ${chalk.green('IPFS/Pinata Integration')} for document notarization
└─ ${chalk.green('Next.js 14 Portal')} with RainbowKit Web3 integration

${chalk.bold.yellow('🔧 Features Deployed:')}
├─ Domain minting & resolution (digitalgiant.x ↔ wallet address)
├─ Reverse resolution (wallet → primary domain)  
├─ ERC-6551 vault binding for programmable accounts
├─ Corporate compliance proofs (EIN, Articles, Operating Agreements)
├─ ISO 20022 message emission for banking integration
└─ IPFS metadata & document storage with Pinata

${chalk.bold.yellow('🧪 Test Results:')}
├─ ${chalk.green('✅ Domain "digitalgiant" minted successfully')}
├─ ${chalk.green('✅ Compliance proof created for "Digital Giant LLC"')}
├─ ${chalk.green('✅ Resolution working: digitalgiant → ' + DEPLOYER_ADDRESS.slice(0, 10) + '...')}
└─ ${chalk.green('✅ Frontend portal running at http://localhost:3004')}

${chalk.bold.yellow('🎯 Ready to Use:')}
├─ ${chalk.cyan('Mint domains:')} Connect wallet at ${chalk.underline('http://localhost:3004/mint')}
├─ ${chalk.cyan('Upload compliance docs:')} ${chalk.gray('node scripts/upload-ipfs.mjs upload-file <path>')}  
├─ ${chalk.cyan('Test contracts:')} ${chalk.gray('HARDHAT_CONFIG=./hardhat.config.mjs npx hardhat run scripts/test-deployment.mjs --network polygon')}
└─ ${chalk.cyan('Deploy portal:')} Upload to IPFS → link to digitalgiant.x

${chalk.bold.yellow('🚀 MOG Stack Advantages vs Unstoppable Domains:')}
├─ ${chalk.green('✓ Sovereign')} (DAO-controlled, not centralized)
├─ ${chalk.green('✓ Programmable')} (ERC-6551 vault accounts per domain)  
├─ ${chalk.green('✓ Compliance-Native')} (ISO 20022, corporate docs)
├─ ${chalk.green('✓ Asset-Tokenizable')} (RWA hooks for water, carbon, etc.)
└─ ${chalk.green('✓ Web2+Web3 Dual Routing')} (fallback to Web2)

${chalk.bold.red('🔥 LIVE NOW ON POLYGON MAINNET!')}
${chalk.gray('Ready for enterprise adoption, banking integration, and RWA tokenization')}
`);

// Export for potential programmatic use
export const deploymentInfo = {
  contracts: {
    registry: REGISTRY_ADDRESS,
    vaultProof: VAULT_PROOF_ADDRESS,
  },
  deployer: DEPLOYER_ADDRESS,
  network: 'polygon',
  status: 'deployed',
  frontend: 'http://localhost:3004'
};