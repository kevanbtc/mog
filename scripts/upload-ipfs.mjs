import { readFileSync } from 'fs';
import { createReadStream } from 'fs';
import FormData from 'form-data';
import fetch from 'node-fetch';
import dotenv from 'dotenv';

dotenv.config();

const PINATA_JWT = process.env.PINATA_JWT;
const PINATA_API_URL = 'https://api.pinata.cloud';

if (!PINATA_JWT) {
  throw new Error('PINATA_JWT environment variable is required');
}

/**
 * Upload file to IPFS via Pinata
 * @param {string} filePath - Path to file to upload
 * @param {object} metadata - Optional metadata for the file
 * @returns {Promise<string>} - IPFS CID
 */
export async function uploadFileToIPFS(filePath, metadata = {}) {
  try {
    const formData = new FormData();
    
    // Add file
    formData.append('file', createReadStream(filePath));
    
    // Add metadata
    const pinataMetadata = JSON.stringify({
      name: metadata.name || `Digital Giant Domain - ${Date.now()}`,
      keyvalues: {
        type: metadata.type || 'domain-proof',
        company: metadata.company || 'Digital Giant',
        timestamp: Date.now(),
        ...metadata.keyvalues
      }
    });
    formData.append('pinataMetadata', pinataMetadata);
    
    // Add options
    const pinataOptions = JSON.stringify({
      cidVersion: 1,
      customPinPolicy: {
        regions: [
          { id: 'FRA1', desiredReplicationCount: 2 },
          { id: 'NYC1', desiredReplicationCount: 2 }
        ]
      }
    });
    formData.append('pinataOptions', pinataOptions);

    const response = await fetch(`${PINATA_API_URL}/pinning/pinFileToIPFS`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${PINATA_JWT}`,
        ...formData.getHeaders()
      },
      body: formData
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Pinata upload failed: ${response.status} - ${error}`);
    }

    const result = await response.json();
    console.log(`✅ File uploaded to IPFS: ${result.IpfsHash}`);
    return result.IpfsHash;
    
  } catch (error) {
    console.error('❌ IPFS upload error:', error);
    throw error;
  }
}

/**
 * Upload JSON metadata to IPFS via Pinata
 * @param {object} jsonData - JSON data to upload
 * @param {object} metadata - Optional metadata for the JSON
 * @returns {Promise<string>} - IPFS CID
 */
export async function uploadJSONToIPFS(jsonData, metadata = {}) {
  try {
    const body = JSON.stringify({
      pinataContent: jsonData,
      pinataMetadata: {
        name: metadata.name || `Digital Giant Metadata - ${Date.now()}`,
        keyvalues: {
          type: metadata.type || 'domain-metadata',
          company: metadata.company || 'Digital Giant',
          timestamp: Date.now(),
          ...metadata.keyvalues
        }
      },
      pinataOptions: {
        cidVersion: 1,
        customPinPolicy: {
          regions: [
            { id: 'FRA1', desiredReplicationCount: 2 },
            { id: 'NYC1', desiredReplicationCount: 2 }
          ]
        }
      }
    });

    const response = await fetch(`${PINATA_API_URL}/pinning/pinJSONToIPFS`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PINATA_JWT}`
      },
      body
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Pinata JSON upload failed: ${response.status} - ${error}`);
    }

    const result = await response.json();
    console.log(`✅ JSON uploaded to IPFS: ${result.IpfsHash}`);
    return result.IpfsHash;
    
  } catch (error) {
    console.error('❌ IPFS JSON upload error:', error);
    throw error;
  }
}

/**
 * Create and upload domain metadata JSON
 * @param {object} domainData - Domain information
 * @returns {Promise<string>} - IPFS CID
 */
export async function createDomainMetadata(domainData) {
  const metadata = {
    name: domainData.domainName,
    description: `Digital Giant domain: ${domainData.domainName}`,
    image: domainData.imageUrl || "https://digitalgiant.x/assets/domain-placeholder.png",
    external_url: `https://digitalgiant.x/domain/${domainData.domainName}`,
    attributes: [
      {
        trait_type: "Domain Type",
        value: domainData.type || "Standard"
      },
      {
        trait_type: "Registration Date",
        value: new Date().toISOString()
      },
      {
        trait_type: "Registry",
        value: "Digital Giant"
      },
      {
        trait_type: "Compliance Level",
        value: domainData.complianceLevel || "Basic"
      }
    ],
    properties: {
      domain: domainData.domainName,
      registry: "Digital Giant",
      blockchain: "Polygon",
      version: "1.0.0"
    }
  };

  return await uploadJSONToIPFS(metadata, {
    name: `Domain: ${domainData.domainName}`,
    type: 'domain-nft-metadata',
    keyvalues: {
      domain: domainData.domainName,
      registry: 'Digital Giant'
    }
  });
}

/**
 * Create and upload compliance proof metadata
 * @param {object} proofData - Compliance proof information
 * @returns {Promise<string>} - IPFS CID
 */
export async function createComplianceProofMetadata(proofData) {
  const metadata = {
    name: `Compliance Proof: ${proofData.companyName}`,
    description: `MOG compliance proof for ${proofData.companyName} - ${proofData.proofType}`,
    image: "https://digitalgiant.x/assets/compliance-seal.png",
    external_url: `https://digitalgiant.x/compliance/${proofData.entityIdentifier}`,
    attributes: [
      {
        trait_type: "Proof Type",
        value: proofData.proofType
      },
      {
        trait_type: "Company Name",
        value: proofData.companyName
      },
      {
        trait_type: "Entity Identifier",
        value: proofData.entityIdentifier
      },
      {
        trait_type: "Issue Date",
        value: new Date().toISOString()
      },
      {
        trait_type: "Compliance Standard",
        value: "ISO 20022"
      }
    ],
    properties: {
      company: proofData.companyName,
      entityId: proofData.entityIdentifier,
      proofType: proofData.proofType,
      standard: "ISO 20022",
      version: "1.0.0"
    }
  };

  return await uploadJSONToIPFS(metadata, {
    name: `Compliance: ${proofData.companyName}`,
    type: 'compliance-proof-metadata',
    keyvalues: {
      company: proofData.companyName,
      entityId: proofData.entityIdentifier,
      proofType: proofData.proofType
    }
  });
}

// CLI interface for direct usage
if (process.argv.length > 2) {
  const command = process.argv[2];
  
  if (command === 'upload-file' && process.argv[3]) {
    const filePath = process.argv[3];
    uploadFileToIPFS(filePath)
      .then(cid => console.log(`CID: ${cid}`))
      .catch(error => {
        console.error(error);
        process.exit(1);
      });
  } else if (command === 'upload-json' && process.argv[3]) {
    const jsonData = JSON.parse(process.argv[3]);
    uploadJSONToIPFS(jsonData)
      .then(cid => console.log(`CID: ${cid}`))
      .catch(error => {
        console.error(error);
        process.exit(1);
      });
  } else {
    console.log('Usage:');
    console.log('  node upload-ipfs.mjs upload-file <file-path>');
    console.log('  node upload-ipfs.mjs upload-json \'<json-string>\'');
  }
}