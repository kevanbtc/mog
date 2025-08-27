// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title VaultProofNFT
/// @notice MOG Compliance layer for corporate documentation proofs
/// @dev Stores EIN confirmation, Articles of Org, Operating Agreement as NFTs
contract VaultProofNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextProofId;
    
    /// @notice Proof types for different corporate documents
    enum ProofType { EIN_CONFIRMATION, ARTICLES_OF_ORG, OPERATING_AGREEMENT, BANKING_DOCS, ISO20022_COMPLIANCE }
    
    /// @notice Proof metadata structure
    struct ProofMetadata {
        ProofType proofType;
        string companyName;
        string entityIdentifier; // EIN, state filing number, etc.
        uint256 issuanceDate;
        string ipfsHash;
        bool isVerified;
        address verifier;
    }
    
    /// @notice Token ID to proof metadata mapping
    mapping(uint256 => ProofMetadata) public proofMetadata;
    /// @notice Company to proof token IDs mapping
    mapping(string => uint256[]) public companyProofs;
    /// @notice Authorized verifiers for compliance validation
    mapping(address => bool) public authorizedVerifiers;
    /// @notice Entity identifier to token ID mapping
    mapping(string => uint256[]) public entityProofs;

    event ProofMinted(
        uint256 indexed tokenId,
        address indexed to,
        ProofType proofType,
        string companyName,
        string entityIdentifier,
        string ipfsHash
    );
    
    event ProofVerified(uint256 indexed tokenId, address indexed verifier);
    event VerifierAuthorized(address indexed verifier, bool authorized);
    event ISO20022MessageEmitted(uint256 indexed tokenId, string messageType, string messageId);

    constructor(address initialOwner)
        ERC721("MOG Vault Proof", "MOGPROOF")
        Ownable(initialOwner)
    {}

    /// @notice Mint a proof NFT for corporate documentation
    function mintProof(
        address to,
        ProofType proofType,
        string memory companyName,
        string memory entityIdentifier,
        string memory ipfsHash
    ) external onlyOwner nonReentrant returns (uint256) {
        uint256 tokenId = ++nextProofId;
        
        proofMetadata[tokenId] = ProofMetadata({
            proofType: proofType,
            companyName: companyName,
            entityIdentifier: entityIdentifier,
            issuanceDate: block.timestamp,
            ipfsHash: ipfsHash,
            isVerified: false,
            verifier: address(0)
        });
        
        companyProofs[companyName].push(tokenId);
        entityProofs[entityIdentifier].push(tokenId);
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", ipfsHash)));
        
        emit ProofMinted(tokenId, to, proofType, companyName, entityIdentifier, ipfsHash);
        
        // Emit ISO 20022 compliance message
        _emitISO20022Message(tokenId, "pacs.008.001.12", _generateMessageId(tokenId));
        
        return tokenId;
    }

    /// @notice Verify a proof NFT (only authorized verifiers)
    function verifyProof(uint256 tokenId) external {
        require(authorizedVerifiers[msg.sender], "Not authorized verifier");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(!proofMetadata[tokenId].isVerified, "Already verified");
        
        proofMetadata[tokenId].isVerified = true;
        proofMetadata[tokenId].verifier = msg.sender;
        
        emit ProofVerified(tokenId, msg.sender);
        
        // Emit ISO 20022 verification message
        _emitISO20022Message(tokenId, "camt.054.001.11", _generateMessageId(tokenId));
    }

    /// @notice Authorize/deauthorize verifiers
    function setAuthorizedVerifier(address verifier, bool authorized) external onlyOwner {
        authorizedVerifiers[verifier] = authorized;
        emit VerifierAuthorized(verifier, authorized);
    }

    /// @notice Get all proofs for a company
    function getCompanyProofs(string memory companyName) external view returns (uint256[] memory) {
        return companyProofs[companyName];
    }

    /// @notice Get all proofs for an entity identifier
    function getEntityProofs(string memory entityIdentifier) external view returns (uint256[] memory) {
        return entityProofs[entityIdentifier];
    }

    /// @notice Check if proof is verified
    function isProofVerified(uint256 tokenId) external view returns (bool) {
        return proofMetadata[tokenId].isVerified;
    }

    /// @notice Get proof metadata
    function getProofMetadata(uint256 tokenId) external view returns (ProofMetadata memory) {
        return proofMetadata[tokenId];
    }

    /// @notice Internal function to emit ISO 20022 messages
    function _emitISO20022Message(uint256 tokenId, string memory messageType, string memory messageId) internal {
        emit ISO20022MessageEmitted(tokenId, messageType, messageId);
    }

    /// @notice Generate unique message ID for ISO 20022 compliance
    function _generateMessageId(uint256 tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(
            "MOG",
            "-",
            block.timestamp,
            "-",
            tokenId
        ));
    }
}