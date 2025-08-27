// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Digital Giant Naming Service
/// @notice Fork of UNS Registry, rebranded for MOG stack with ERC-6551 vault binding
contract DigitalGiantRegistry is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextDomainId;
    
    /// @notice Domain name to token ID mapping
    mapping(string => uint256) public domainToTokenId;
    /// @notice Token ID to domain name mapping
    mapping(uint256 => string) public tokenIdToDomain;
    /// @notice Domain resolution mapping (domain => wallet address)
    mapping(string => address) public domainResolution;
    /// @notice Reverse resolution mapping (wallet => primary domain)
    mapping(address => string) public reverseResolution;
    /// @notice ERC-6551 vault addresses for each domain
    mapping(uint256 => address) public domainVaults;
    /// @notice Compliance proof IPFS CIDs for each domain
    mapping(uint256 => string) public complianceProofs;

    event DomainMinted(uint256 indexed tokenId, string indexed domainName, address indexed to, string ipfsCID);
    event DomainResolved(string indexed domainName, address indexed resolvedAddress);
    event VaultBound(uint256 indexed tokenId, address indexed vaultAddress);
    event ComplianceProofAdded(uint256 indexed tokenId, string ipfsCID);

    constructor(address initialOwner)
        ERC721("Digital Giant Naming Service", "DGNS")
        Ownable(initialOwner)
    {}

    /// @notice Mint a new Digital Giant domain NFT
    function mintDomain(
        address to, 
        string memory domainName, 
        string memory ipfsCID
    ) external onlyOwner nonReentrant {
        require(bytes(domainName).length > 0, "Domain name cannot be empty");
        require(domainToTokenId[domainName] == 0, "Domain already exists");
        
        uint256 tokenId = ++nextDomainId;
        
        domainToTokenId[domainName] = tokenId;
        tokenIdToDomain[tokenId] = domainName;
        domainResolution[domainName] = to;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", ipfsCID)));
        
        emit DomainMinted(tokenId, domainName, to, ipfsCID);
    }

    /// @notice Resolve domain to wallet address
    function resolveDomain(string memory domainName) external view returns (address) {
        return domainResolution[domainName];
    }

    /// @notice Set primary domain for reverse resolution
    function setPrimaryDomain(string memory domainName) external {
        uint256 tokenId = domainToTokenId[domainName];
        require(tokenId != 0, "Domain does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not domain owner");
        
        reverseResolution[msg.sender] = domainName;
        domainResolution[domainName] = msg.sender;
        
        emit DomainResolved(domainName, msg.sender);
    }

    /// @notice Bind ERC-6551 vault to domain
    function bindVault(uint256 tokenId, address vaultAddress) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        domainVaults[tokenId] = vaultAddress;
        emit VaultBound(tokenId, vaultAddress);
    }

    /// @notice Add compliance proof IPFS CID
    function addComplianceProof(uint256 tokenId, string memory ipfsCID) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        complianceProofs[tokenId] = ipfsCID;
        emit ComplianceProofAdded(tokenId, ipfsCID);
    }

    /// @notice Get domain vault address
    function getDomainVault(uint256 tokenId) external view returns (address) {
        return domainVaults[tokenId];
    }

    /// @notice Get compliance proof for domain
    function getComplianceProof(uint256 tokenId) external view returns (string memory) {
        return complianceProofs[tokenId];
    }
}
