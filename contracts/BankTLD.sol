// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Bank TLD Registry
/// @notice Premium banking sector domain registry with regulatory compliance
contract BankTLD is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextDomainId;
    
    /// @notice Banking institution types
    enum BankType { 
        COMMERCIAL_BANK,
        INVESTMENT_BANK, 
        CENTRAL_BANK,
        CREDIT_UNION,
        FINTECH,
        NEOBANK,
        CRYPTO_EXCHANGE
    }
    
    enum ComplianceLevel { BASIC, ENHANCED, PREMIUM }
    
    /// @notice Banking-specific metadata
    struct BankMetadata {
        BankType bankType;
        ComplianceLevel complianceLevel;
        string regulatoryLicense; // Banking license number
        string jurisdictions; // Operating jurisdictions (comma-separated)
        uint256 capitalRequirement; // Required capital in USD
        bool swiftEnabled; // SWIFT network integration
        bool iso20022Compliant; // ISO 20022 messaging compliance
        uint256 lastAuditDate;
        string regulatorIPFS; // Regulatory filing documents
        bytes32 swiftBIC; // Bank Identifier Code
    }
    
    /// @notice Domain mappings
    mapping(string => uint256) public domainToTokenId;
    mapping(uint256 => string) public tokenIdToDomain;
    mapping(string => address) public domainResolution;
    mapping(address => string) public reverseResolution;
    mapping(uint256 => address) public domainVaults;
    mapping(uint256 => BankMetadata) public bankMetadata;
    
    /// @notice Premium banking pricing (in wei)
    mapping(ComplianceLevel => uint256) public compliancePricing;
    
    /// @notice Authorized bank regulators
    mapping(address => bool) public authorizedRegulatorsGlobal;
    mapping(address => mapping(string => bool)) public authorizedRegulatorsByJurisdiction;
    
    /// @notice SWIFT network integration
    mapping(uint256 => bool) public swiftNetworkAccess;
    mapping(bytes32 => uint256) public bicToTokenId; // BIC to token mapping
    
    event BankDomainMinted(uint256 indexed tokenId, string indexed domainName, address indexed to, BankType bankType);
    event RegulatoryApproval(uint256 indexed tokenId, address regulator, string jurisdiction);
    event SWIFTIntegration(uint256 indexed tokenId, bytes32 bic, bool enabled);
    event ISO20022BankMessage(uint256 indexed tokenId, string messageType, string transactionId);
    event ComplianceAudit(uint256 indexed tokenId, address auditor, string reportIPFS, bool passed);
    event CapitalRequirementUpdated(uint256 indexed tokenId, uint256 oldAmount, uint256 newAmount);

    constructor(address initialOwner) 
        ERC721("Bank Digital Naming Service", "BANK") 
        Ownable(initialOwner) 
    {
        // Ultra-premium banking sector pricing
        compliancePricing[ComplianceLevel.BASIC] = 1 ether;       // ~$2,500
        compliancePricing[ComplianceLevel.ENHANCED] = 10 ether;   // ~$25,000
        compliancePricing[ComplianceLevel.PREMIUM] = 50 ether;    // ~$125,000
    }

    /// @notice Mint banking domain with regulatory compliance
    function mintBankDomain(
        address to,
        string memory domainName,
        string memory ipfsCID,
        BankType bankType,
        ComplianceLevel complianceLevel,
        string memory regulatoryLicense,
        string memory jurisdictions,
        uint256 capitalRequirement,
        bytes32 swiftBIC
    ) external payable onlyOwner nonReentrant {
        require(bytes(domainName).length > 0, "Domain name cannot be empty");
        require(domainToTokenId[domainName] == 0, "Domain already exists");
        require(msg.value >= compliancePricing[complianceLevel], "Insufficient payment");
        require(swiftBIC == bytes32(0) || bicToTokenId[swiftBIC] == 0, "BIC already registered");
        
        uint256 tokenId = ++nextDomainId;
        
        // Standard domain setup
        domainToTokenId[domainName] = tokenId;
        tokenIdToDomain[tokenId] = domainName;
        domainResolution[domainName] = to;
        
        // Banking-specific metadata
        bankMetadata[tokenId] = BankMetadata({
            bankType: bankType,
            complianceLevel: complianceLevel,
            regulatoryLicense: regulatoryLicense,
            jurisdictions: jurisdictions,
            capitalRequirement: capitalRequirement,
            swiftEnabled: swiftBIC != bytes32(0),
            iso20022Compliant: true, // Default compliance
            lastAuditDate: 0,
            regulatorIPFS: ipfsCID,
            swiftBIC: swiftBIC
        });
        
        // Map BIC if provided
        if (swiftBIC != bytes32(0)) {
            bicToTokenId[swiftBIC] = tokenId;
            swiftNetworkAccess[tokenId] = true;
        }
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", ipfsCID)));
        
        emit BankDomainMinted(tokenId, domainName, to, bankType);
        emit ISO20022BankMessage(tokenId, "acmt.001.001.05", _generateTransactionId(tokenId));
        
        if (swiftBIC != bytes32(0)) {
            emit SWIFTIntegration(tokenId, swiftBIC, true);
        }
        
        // Refund excess
        if (msg.value > compliancePricing[complianceLevel]) {
            payable(msg.sender).transfer(msg.value - compliancePricing[complianceLevel]);
        }
    }

    /// @notice Regulatory approval by authorized regulators
    function grantRegulatoryApproval(
        uint256 tokenId,
        string memory jurisdiction,
        string memory approvalDocumentIPFS
    ) external {
        require(
            authorizedRegulatorsGlobal[msg.sender] || 
            authorizedRegulatorsByJurisdiction[msg.sender][jurisdiction],
            "Not authorized regulator"
        );
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        bankMetadata[tokenId].regulatorIPFS = approvalDocumentIPFS;
        bankMetadata[tokenId].lastAuditDate = block.timestamp;
        
        emit RegulatoryApproval(tokenId, msg.sender, jurisdiction);
        emit ISO20022BankMessage(tokenId, "auth.001.001.01", _generateTransactionId(tokenId));
    }

    /// @notice Update capital requirements
    function updateCapitalRequirement(
        uint256 tokenId,
        uint256 newCapitalRequirement,
        string memory filingIPFS
    ) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        uint256 oldRequirement = bankMetadata[tokenId].capitalRequirement;
        bankMetadata[tokenId].capitalRequirement = newCapitalRequirement;
        bankMetadata[tokenId].regulatorIPFS = filingIPFS;
        
        emit CapitalRequirementUpdated(tokenId, oldRequirement, newCapitalRequirement);
    }

    /// @notice Enable/disable SWIFT network access
    function updateSWIFTAccess(
        uint256 tokenId,
        bool enabled,
        bytes32 newBIC
    ) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        // Remove old BIC mapping if exists
        bytes32 oldBIC = bankMetadata[tokenId].swiftBIC;
        if (oldBIC != bytes32(0)) {
            bicToTokenId[oldBIC] = 0;
        }
        
        // Add new BIC mapping
        if (enabled && newBIC != bytes32(0)) {
            require(bicToTokenId[newBIC] == 0, "BIC already registered");
            bicToTokenId[newBIC] = tokenId;
            bankMetadata[tokenId].swiftBIC = newBIC;
        }
        
        swiftNetworkAccess[tokenId] = enabled;
        bankMetadata[tokenId].swiftEnabled = enabled;
        
        emit SWIFTIntegration(tokenId, newBIC, enabled);
    }

    /// @notice Regulatory compliance audit
    function recordComplianceAudit(
        uint256 tokenId,
        bool passed,
        string memory auditReportIPFS
    ) external {
        require(authorizedRegulatorsGlobal[msg.sender], "Not authorized auditor");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        bankMetadata[tokenId].lastAuditDate = block.timestamp;
        bankMetadata[tokenId].regulatorIPFS = auditReportIPFS;
        
        emit ComplianceAudit(tokenId, msg.sender, auditReportIPFS, passed);
    }

    /// @notice Authorize regulators
    function setAuthorizedRegulator(address regulator, bool authorized) external onlyOwner {
        authorizedRegulatorsGlobal[regulator] = authorized;
    }

    /// @notice Authorize jurisdiction-specific regulators
    function setJurisdictionRegulator(
        address regulator, 
        string memory jurisdiction, 
        bool authorized
    ) external onlyOwner {
        authorizedRegulatorsByJurisdiction[regulator][jurisdiction] = authorized;
    }

    /// @notice Get banking metadata
    function getBankMetadata(uint256 tokenId) external view returns (BankMetadata memory) {
        return bankMetadata[tokenId];
    }

    /// @notice Resolve domain by BIC code
    function resolveBIC(bytes32 bic) external view returns (address) {
        uint256 tokenId = bicToTokenId[bic];
        if (tokenId == 0) return address(0);
        return domainResolution[tokenIdToDomain[tokenId]];
    }

    /// @notice Check compliance status
    function isCompliant(uint256 tokenId) external view returns (bool) {
        BankMetadata memory metadata = bankMetadata[tokenId];
        return metadata.iso20022Compliant && 
               (block.timestamp - metadata.lastAuditDate) < 365 days;
    }

    /// @notice Standard resolution functions
    function resolveDomain(string memory domainName) external view returns (address) {
        return domainResolution[domainName];
    }

    function setPrimaryDomain(string memory domainName) external {
        uint256 tokenId = domainToTokenId[domainName];
        require(tokenId != 0, "Domain does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not domain owner");
        
        reverseResolution[msg.sender] = domainName;
        domainResolution[domainName] = msg.sender;
    }

    function bindVault(uint256 tokenId, address vaultAddress) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        domainVaults[tokenId] = vaultAddress;
    }

    function updateCompliancePricing(ComplianceLevel level, uint256 newPrice) external onlyOwner {
        compliancePricing[level] = newPrice;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Generate transaction ID for ISO 20022 messages
    function _generateTransactionId(uint256 tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(
            "BANK",
            "-",
            Strings.toString(tokenId),
            "-",
            Strings.toString(block.timestamp)
        ));
    }
}

// Import required for Strings utility
import "@openzeppelin/contracts/utils/Strings.sol";