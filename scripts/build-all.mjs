#!/usr/bin/env node

import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

console.log('🦄 Digital Giant x MOG Build Script');
console.log('═══════════════════════════════════\n');

const steps = [
  {
    name: '📦 Install Dependencies',
    command: 'npm install',
    cwd: rootDir
  },
  {
    name: '🔨 Compile Smart Contracts',
    command: 'npm run compile',
    cwd: rootDir
  },
  {
    name: '🏗️ Build Frontend Portal',
    command: 'npm run build',
    cwd: join(rootDir, 'portal'),
    optional: true // Skip if portal not ready
  }
];

async function runStep(step) {
  console.log(`\n${step.name}`);
  console.log('─'.repeat(40));
  
  try {
    const output = execSync(step.command, {
      cwd: step.cwd,
      encoding: 'utf-8',
      stdio: 'pipe'
    });
    
    console.log('✅ Success');
    if (output && output.trim()) {
      console.log(output.split('\n').slice(-3).join('\n'));
    }
  } catch (error) {
    if (step.optional) {
      console.log('⚠️  Optional step skipped');
      return;
    }
    
    console.error('❌ Failed');
    console.error(error.stdout || error.message);
    process.exit(1);
  }
}

async function main() {
  for (const step of steps) {
    await runStep(step);
  }
  
  console.log('\n🎉 Build Complete!');
  console.log('═══════════════════════════════════');
  console.log('📋 Next Steps:');
  console.log('1. Copy .env.example to .env and configure');
  console.log('2. Deploy contracts: npm run deploy');
  console.log('3. Start frontend: cd portal && npm run dev');
  console.log('4. Configure domain resolution');
  console.log('\n🔗 Architecture:');
  console.log('• DigitalGiantRegistry: Domain NFTs with resolution');
  console.log('• VaultProofNFT: MOG compliance layer');
  console.log('• Portal: Next.js frontend with Web3 integration');
  console.log('• IPFS: Pinata integration for document storage');
  console.log('\n🚀 Ready for Digital Giant x MOG deployment!');
}

main().catch(console.error);