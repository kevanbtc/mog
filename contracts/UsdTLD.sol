// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title USD TLD Registry
/// @notice Premium currency/DeFi domain registry with stablecoin and forex integration
contract UsdTLD is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextDomainId;
    
    /// @notice Currency/DeFi sector types
    enum SectorType { 
        STABLECOIN, 
        FOREX_TRADING, 
        PAYMENT_PROCESSOR, 
        REMITTANCE, 
        CBDC,
        DEFI_PROTOCOL,
        TREASURY_MANAGEMENT,
        CROSS_BORDER_PAYMENTS
    }
    
    enum ComplianceLevel { BASIC, AML_KYC, BANKING_GRADE, INSTITUTIONAL }
    
    /// @notice USD/Currency-specific metadata
    struct CurrencyMetadata {
        SectorType sectorType;
        ComplianceLevel complianceLevel;
        uint256 dollarReserveBacking; // USD reserves backing in wei equivalent
        string auditFirmIPFS; // Independent audit reports
        bool fedCompliant; // Federal Reserve compliance status
        bool fatfCompliant; // FATF anti-money laundering compliance
        string regulatoryLicenseIPFS; // MSB/Banking license documents
        uint256 dailyVolumeCapacityUSD; // Daily transaction volume capacity
        uint256 lastComplianceAuditDate;
        bytes32 swiftCode; // For traditional banking integration
        string treasuryManagementIPFS; // Treasury and risk management docs
    }
    
    /// @notice Domain mappings
    mapping(string => uint256) public domainToTokenId;
    mapping(uint256 => string) public tokenIdToDomain;
    mapping(string => address) public domainResolution;
    mapping(address => string) public reverseResolution;
    mapping(uint256 => address) public domainVaults;
    mapping(uint256 => CurrencyMetadata) public currencyMetadata;
    
    /// @notice Compliance-based pricing (in wei)
    mapping(ComplianceLevel => uint256) public compliancePricing;
    
    /// @notice Authorized financial regulators and auditors
    mapping(address => bool) public authorizedRegulatorsGlobal;
    mapping(address => mapping(string => bool)) public authorizedRegulatorsByJurisdiction;
    mapping(address => bool) public authorizedAuditors;
    
    /// @notice Reserve backing tracking
    mapping(uint256 => mapping(address => uint256)) public reserveDeposits;
    mapping(uint256 => uint256) public totalReserveBacking;
    
    event UsdDomainMinted(uint256 indexed tokenId, string indexed domainName, address indexed to, SectorType sectorType);
    event ReserveBackingUpdated(uint256 indexed tokenId, uint256 newReserveAmount, address auditor);
    event ComplianceVerification(uint256 indexed tokenId, ComplianceLevel level, address regulator);
    event ISO20022CurrencyMessage(uint256 indexed tokenId, string messageType, uint256 transactionVolume);
    event AMLKYCVerification(uint256 indexed tokenId, address verifier, string reportIPFS);
    event TreasuryAudit(uint256 indexed tokenId, address auditor, string auditReportIPFS, bool passed);
    event CrossBorderPaymentAuthorization(uint256 indexed tokenId, string jurisdiction, bool authorized);

    constructor(address initialOwner) 
        ERC721("USD Digital Naming Service", "USD") 
        Ownable(initialOwner) 
    {
        // Ultra-premium currency/DeFi pricing based on compliance requirements
        compliancePricing[ComplianceLevel.BASIC] = 0.5 ether;          // ~$1,250
        compliancePricing[ComplianceLevel.AML_KYC] = 5 ether;          // ~$12,500
        compliancePricing[ComplianceLevel.BANKING_GRADE] = 25 ether;   // ~$62,500
        compliancePricing[ComplianceLevel.INSTITUTIONAL] = 100 ether;  // ~$250,000
    }

    /// @notice Mint USD/currency domain with regulatory compliance
    function mintUsdDomain(
        address to,
        string memory domainName,
        string memory ipfsCID,
        SectorType sectorType,
        ComplianceLevel complianceLevel,
        uint256 dollarReserveBacking,
        string memory regulatoryLicenseIPFS,
        uint256 dailyVolumeCapacityUSD,
        bytes32 swiftCode
    ) external payable onlyOwner nonReentrant {
        require(bytes(domainName).length > 0, "Domain name cannot be empty");
        require(domainToTokenId[domainName] == 0, "Domain already exists");
        require(msg.value >= compliancePricing[complianceLevel], "Insufficient payment");
        require(dollarReserveBacking > 0, "Reserve backing required");
        
        uint256 tokenId = ++nextDomainId;
        
        // Standard domain setup
        domainToTokenId[domainName] = tokenId;
        tokenIdToDomain[tokenId] = domainName;
        domainResolution[domainName] = to;
        
        // Currency-specific metadata
        currencyMetadata[tokenId] = CurrencyMetadata({
            sectorType: sectorType,
            complianceLevel: complianceLevel,
            dollarReserveBacking: dollarReserveBacking,
            auditFirmIPFS: ipfsCID,
            fedCompliant: false, // Requires verification
            fatfCompliant: false, // Requires verification
            regulatoryLicenseIPFS: regulatoryLicenseIPFS,
            dailyVolumeCapacityUSD: dailyVolumeCapacityUSD,
            lastComplianceAuditDate: 0,
            swiftCode: swiftCode,
            treasuryManagementIPFS: ipfsCID
        });
        
        // Initialize reserve backing
        totalReserveBacking[tokenId] = dollarReserveBacking;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", ipfsCID)));
        
        emit UsdDomainMinted(tokenId, domainName, to, sectorType);
        emit ISO20022CurrencyMessage(tokenId, "pacs.008.001.12", dailyVolumeCapacityUSD);
        
        // Refund excess
        if (msg.value > compliancePricing[complianceLevel]) {
            payable(msg.sender).transfer(msg.value - compliancePricing[complianceLevel]);
        }
    }

    /// @notice Update reserve backing with audit verification
    function updateReserveBacking(
        uint256 tokenId,
        uint256 newReserveAmount,
        string memory auditReportIPFS
    ) external {
        require(authorizedAuditors[msg.sender], "Not authorized auditor");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        currencyMetadata[tokenId].dollarReserveBacking = newReserveAmount;
        currencyMetadata[tokenId].auditFirmIPFS = auditReportIPFS;
        currencyMetadata[tokenId].lastComplianceAuditDate = block.timestamp;
        totalReserveBacking[tokenId] = newReserveAmount;
        
        emit ReserveBackingUpdated(tokenId, newReserveAmount, msg.sender);
    }

    /// @notice Federal Reserve compliance verification
    function verifyFedCompliance(
        uint256 tokenId,
        bool compliant,
        string memory complianceDocumentIPFS
    ) external {
        require(
            authorizedRegulatorsGlobal[msg.sender] || 
            authorizedRegulatorsByJurisdiction[msg.sender]["USA"],
            "Not authorized Fed regulator"
        );
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        currencyMetadata[tokenId].fedCompliant = compliant;
        currencyMetadata[tokenId].regulatoryLicenseIPFS = complianceDocumentIPFS;
        currencyMetadata[tokenId].lastComplianceAuditDate = block.timestamp;
        
        emit ComplianceVerification(tokenId, currencyMetadata[tokenId].complianceLevel, msg.sender);
    }

    /// @notice FATF AML/KYC compliance verification
    function verifyAMLKYCCompliance(
        uint256 tokenId,
        bool compliant,
        string memory kycReportIPFS
    ) external {
        require(authorizedRegulatorsGlobal[msg.sender], "Not authorized regulator");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        currencyMetadata[tokenId].fatfCompliant = compliant;
        currencyMetadata[tokenId].treasuryManagementIPFS = kycReportIPFS;
        currencyMetadata[tokenId].lastComplianceAuditDate = block.timestamp;
        
        emit AMLKYCVerification(tokenId, msg.sender, kycReportIPFS);
    }

    /// @notice Treasury management audit
    function recordTreasuryAudit(
        uint256 tokenId,
        bool passed,
        string memory auditReportIPFS
    ) external {
        require(authorizedAuditors[msg.sender], "Not authorized auditor");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        currencyMetadata[tokenId].treasuryManagementIPFS = auditReportIPFS;
        currencyMetadata[tokenId].lastComplianceAuditDate = block.timestamp;
        
        emit TreasuryAudit(tokenId, msg.sender, auditReportIPFS, passed);
    }

    /// @notice Authorize cross-border payment operations
    function authorizeCrossBorderPayments(
        uint256 tokenId,
        string memory jurisdiction,
        bool authorized,
        string memory licenseIPFS
    ) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        currencyMetadata[tokenId].regulatoryLicenseIPFS = licenseIPFS;
        
        emit CrossBorderPaymentAuthorization(tokenId, jurisdiction, authorized);
    }

    /// @notice Set authorized regulators and auditors
    function setAuthorizedRegulator(address regulator, bool authorized) external onlyOwner {
        authorizedRegulatorsGlobal[regulator] = authorized;
    }

    function setJurisdictionRegulator(
        address regulator, 
        string memory jurisdiction, 
        bool authorized
    ) external onlyOwner {
        authorizedRegulatorsByJurisdiction[regulator][jurisdiction] = authorized;
    }

    function setAuthorizedAuditor(address auditor, bool authorized) external onlyOwner {
        authorizedAuditors[auditor] = authorized;
    }

    /// @notice Get currency metadata
    function getCurrencyMetadata(uint256 tokenId) external view returns (CurrencyMetadata memory) {
        return currencyMetadata[tokenId];
    }

    /// @notice Calculate collateralization ratio (for stablecoins)
    function getCollateralizationRatio(uint256 tokenId) external view returns (uint256) {
        // Returns basis points (e.g., 10000 = 100% collateralized)
        // This would integrate with actual reserve tracking in production
        return 10000; // Placeholder for 100% backing
    }

    /// @notice Check full regulatory compliance status
    function isFullyCompliant(uint256 tokenId) external view returns (bool) {
        CurrencyMetadata memory metadata = currencyMetadata[tokenId];
        return metadata.fedCompliant && 
               metadata.fatfCompliant && 
               (block.timestamp - metadata.lastComplianceAuditDate) < 365 days &&
               metadata.dollarReserveBacking > 0;
    }

    /// @notice Domain resolution
    function resolveDomain(string memory domainName) external view returns (address) {
        return domainResolution[domainName];
    }

    /// @notice Set primary domain
    function setPrimaryDomain(string memory domainName) external {
        uint256 tokenId = domainToTokenId[domainName];
        require(tokenId != 0, "Domain does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not domain owner");
        
        reverseResolution[msg.sender] = domainName;
        domainResolution[domainName] = msg.sender;
    }

    /// @notice Bind ERC-6551 vault
    function bindVault(uint256 tokenId, address vaultAddress) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        domainVaults[tokenId] = vaultAddress;
    }

    /// @notice Update pricing
    function updateCompliancePricing(ComplianceLevel level, uint256 newPrice) external onlyOwner {
        compliancePricing[level] = newPrice;
    }

    /// @notice Withdraw funds
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Enhanced tokenURI with currency metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        string memory baseURI = super.tokenURI(tokenId);
        CurrencyMetadata memory metadata = currencyMetadata[tokenId];
        
        // Could enhance with on-chain compliance status metadata
        return baseURI;
    }
}