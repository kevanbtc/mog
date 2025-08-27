# 🦄 Digital Giant x MOG Sovereign Domains

A complete Unstoppable-Domains-style registry and resolution stack built on **Polygon** with **MOG compliance integration**, **ERC-6551 vault binding**, and **IPFS document notarization**.

## 🏗️ Architecture

### Smart Contracts
- **DigitalGiantRegistry**: ERC-721 domain NFTs with resolution and vault binding
- **VaultProofNFT**: ISO 20022 compliance layer for corporate documentation

### Frontend Portal
- **Next.js 14** with App Router and ESM support
- **Tailwind CSS** with custom MOG theme
- **RainbowKit + Wagmi** for Web3 integration
- **IPFS/Pinata** integration for document storage

### Resolution Layer
- Domain → Wallet resolution
- Reverse resolution (wallet → primary domain)
- ERC-6551 vault binding per domain
- Compliance proof verification

## 🚀 Quick Start

### 1. Environment Setup
```bash
# Clone and install dependencies
cd digital-giant-domains
cp .env.example .env
# Fill in your values in .env

# Run complete build
node scripts/build-all.mjs
```

### 2. Deploy Contracts
```bash
# Configure RPC_URL and PRIVATE_KEY in .env
npm run deploy
```

### 3. Start Frontend
```bash
cd portal
cp .env.local.example .env.local
# Add contract addresses from deployment
npm run dev
```

## 📁 Project Structure

```
digital-giant-domains/
├── contracts/
│   ├── DigitalGiantRegistry.sol    # Main domain registry
│   └── VaultProofNFT.sol          # MOG compliance layer
├── scripts/
│   ├── deploy.mjs                 # Deployment script
│   ├── upload-ipfs.mjs            # IPFS utilities
│   └── build-all.mjs              # Complete build script
├── portal/                        # Next.js frontend
│   ├── app/
│   │   ├── page.tsx               # Homepage
│   │   ├── mint/                  # Domain minting
│   │   └── layout.tsx             # App layout with Web3
│   ├── lib/
│   │   └── wagmi.ts               # Web3 configuration
│   └── components/                # Reusable components
├── upstream-resolution/           # Forked resolution layer
├── upstream-ui/                   # Forked UI components
└── upstream-uns/                  # Forked UNS contracts
```

## 🛠️ Key Features

### Domain Registry
- **ERC-721 NFTs** for domain ownership
- **Domain resolution** (digitalgiant.x → 0x123...)
- **Reverse resolution** (0x123... → digitalgiant.x)
- **Subdomain support** for DAO issuance

### ERC-6551 Vault Binding
- Each domain becomes a **programmable account**
- Vault addresses stored on-chain
- Advanced DeFi integration capabilities

### MOG Compliance Layer
- **ISO 20022** message emission
- Corporate document verification
- **EIN confirmation**, Articles of Org, Operating Agreement
- Authorized verifier system

### IPFS Integration
- **Pinata** for reliable IPFS pinning
- Metadata and document storage
- **CID-based** proof verification
- Redundant regional replication

## 🔧 Configuration

### Environment Variables (.env)
```env
# Blockchain
RPC_URL=https://polygon-rpc.com
PRIVATE_KEY=0xYOUR_PRIVATE_KEY

# IPFS
PINATA_JWT=eyJhbGciOiJI...YOUR_JWT

# Contracts (filled after deployment)
DIGITAL_GIANT_REGISTRY=0x...
VAULT_PROOF_NFT=0x...
```

### Frontend Environment (.env.local)
```env
NEXT_PUBLIC_REGISTRY_ADDRESS=0x...
NEXT_PUBLIC_VAULT_PROOF_ADDRESS=0x...
NEXT_PUBLIC_RPC_URL=https://polygon-rpc.com
NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your-project-id
```

## 📋 Usage Examples

### Mint Domain
```javascript
// Via frontend or direct contract call
await registry.mintDomain(
  "0xRecipientAddress",
  "digitalgiant", 
  "QmYourIPFSHash"
);
```

### Upload Compliance Docs
```javascript
import { uploadFileToIPFS, createComplianceProofMetadata } from './scripts/upload-ipfs.mjs';

const cid = await uploadFileToIPFS('./articles-of-org.pdf');
const metadataCID = await createComplianceProofMetadata({
  companyName: "Digital Giant LLC",
  entityIdentifier: "EIN123456789",
  proofType: "ARTICLES_OF_ORG"
});
```

### Resolve Domain
```javascript
const address = await registry.resolveDomain("digitalgiant");
// Returns: 0x123...
```

## 🔗 Integration with MOG Stack

### ISO 20022 Compliance
- Automatic message emission on proof creation
- Message types: `pacs.008.001.12`, `camt.054.001.11`
- Banking-grade compliance standards

### Corporate Documentation
- **EIN Confirmation**: Tax ID verification
- **Articles of Organization**: Corporate structure
- **Operating Agreement**: Governance documentation
- **Banking Documents**: Financial compliance

### Vault Operations
- Each domain = ERC-6551 account
- Programmable corporate actions
- DeFi integration capabilities
- Multi-signature support

## 🚦 Deployment Checklist

- [ ] Configure environment variables
- [ ] Deploy DigitalGiantRegistry
- [ ] Deploy VaultProofNFT  
- [ ] Set authorized compliance verifiers
- [ ] Configure IPFS/Pinata integration
- [ ] Deploy frontend portal
- [ ] Test domain minting and resolution
- [ ] Verify compliance proof system

## 🔐 Security Features

- **ReentrancyGuard** on all state-changing functions
- **Ownable** access control for admin functions
- **Input validation** and require statements
- **IPFS content addressing** for tamper-proof documents

## 🌐 Network Support

- **Primary**: Polygon Mainnet
- **Testnet**: Polygon Mumbai (for development)
- **Future**: Base, Arbitrum, Optimism

## 📞 Support

For issues and feature requests, create an issue in the repository or contact the Digital Giant x MOG development team.

---

**Built with ❤️ for the sovereign domain ecosystem**