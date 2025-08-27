// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Oil TLD Registry  
/// @notice Premium energy sector domain registry with commodity integration
contract OilTLD is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextDomainId;
    
    /// @notice Oil industry tiers
    enum IndustryTier { UPSTREAM, MIDSTREAM, DOWNSTREAM, TRADING, REFINING }
    enum PricingTier { STANDARD, PREMIUM, ENTERPRISE }
    
    /// @notice Oil-specific metadata
    struct OilMetadata {
        IndustryTier industryTier;
        PricingTier pricingTier;
        uint256 barrelReserves; // Oil reserves backing in barrels
        string facilityLocation; // Production facility location
        bool ESGCompliant; // Environmental compliance status
        uint256 lastInspectionDate;
        string regulatoryLicenseIPFS; // Regulatory compliance docs
        uint256 dailyProductionCapacity; // Barrels per day
    }
    
    /// @notice Domain mappings
    mapping(string => uint256) public domainToTokenId;
    mapping(uint256 => string) public tokenIdToDomain;
    mapping(string => address) public domainResolution;
    mapping(address => string) public reverseResolution;
    mapping(uint256 => address) public domainVaults;
    mapping(uint256 => OilMetadata) public oilMetadata;
    
    /// @notice Pricing structure (in wei)
    mapping(PricingTier => uint256) public tierPricing;
    
    /// @notice Authorized regulatory inspectors
    mapping(address => bool) public authorizedInspectors;
    
    event OilDomainMinted(uint256 indexed tokenId, string indexed domainName, address indexed to, IndustryTier tier);
    event ProductionUpdated(uint256 indexed tokenId, uint256 barrelReserves, uint256 dailyCapacity);
    event ESGComplianceUpdated(uint256 indexed tokenId, bool compliant, address inspector);
    event ISO20022OilMessage(uint256 indexed tokenId, string messageType, uint256 barrelValue);
    event RegulatoryInspection(uint256 indexed tokenId, address inspector, string reportIPFS);

    constructor(address initialOwner) 
        ERC721("Oil Digital Naming Service", "OIL") 
        Ownable(initialOwner) 
    {
        // Premium energy sector pricing
        tierPricing[PricingTier.STANDARD] = 0.05 ether;      // ~$125
        tierPricing[PricingTier.PREMIUM] = 0.5 ether;        // ~$1,250
        tierPricing[PricingTier.ENTERPRISE] = 5 ether;       // ~$12,500
    }

    /// @notice Mint oil industry domain
    function mintOilDomain(
        address to,
        string memory domainName,
        string memory ipfsCID,
        IndustryTier industryTier,
        PricingTier pricingTier,
        uint256 barrelReserves,
        string memory facilityLocation,
        uint256 dailyProductionCapacity
    ) external payable onlyOwner nonReentrant {
        require(bytes(domainName).length > 0, "Domain name cannot be empty");
        require(domainToTokenId[domainName] == 0, "Domain already exists");
        require(msg.value >= tierPricing[pricingTier], "Insufficient payment");
        
        uint256 tokenId = ++nextDomainId;
        
        // Standard domain setup
        domainToTokenId[domainName] = tokenId;
        tokenIdToDomain[tokenId] = domainName;
        domainResolution[domainName] = to;
        
        // Oil-specific metadata
        oilMetadata[tokenId] = OilMetadata({
            industryTier: industryTier,
            pricingTier: pricingTier,
            barrelReserves: barrelReserves,
            facilityLocation: facilityLocation,
            ESGCompliant: false, // Requires inspection
            lastInspectionDate: 0,
            regulatoryLicenseIPFS: ipfsCID,
            dailyProductionCapacity: dailyProductionCapacity
        });
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", ipfsCID)));
        
        emit OilDomainMinted(tokenId, domainName, to, industryTier);
        emit ISO20022OilMessage(tokenId, "pacs.008.001.12", barrelReserves * 80); // ~$80/barrel
        
        // Refund excess
        if (msg.value > tierPricing[pricingTier]) {
            payable(msg.sender).transfer(msg.value - tierPricing[pricingTier]);
        }
    }

    /// @notice Update production capacity and reserves
    function updateProduction(
        uint256 tokenId,
        uint256 barrelReserves,
        uint256 dailyCapacity,
        string memory updatedLicenseIPFS
    ) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        oilMetadata[tokenId].barrelReserves = barrelReserves;
        oilMetadata[tokenId].dailyProductionCapacity = dailyCapacity;
        oilMetadata[tokenId].regulatoryLicenseIPFS = updatedLicenseIPFS;
        
        emit ProductionUpdated(tokenId, barrelReserves, dailyCapacity);
    }

    /// @notice ESG compliance inspection (authorized inspectors only)
    function updateESGCompliance(
        uint256 tokenId,
        bool compliant,
        string memory inspectionReportIPFS
    ) external {
        require(authorizedInspectors[msg.sender], "Not authorized inspector");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        oilMetadata[tokenId].ESGCompliant = compliant;
        oilMetadata[tokenId].lastInspectionDate = block.timestamp;
        oilMetadata[tokenId].regulatoryLicenseIPFS = inspectionReportIPFS;
        
        emit ESGComplianceUpdated(tokenId, compliant, msg.sender);
        emit RegulatoryInspection(tokenId, msg.sender, inspectionReportIPFS);
    }

    /// @notice Authorize regulatory inspectors
    function setAuthorizedInspector(address inspector, bool authorized) external onlyOwner {
        authorizedInspectors[inspector] = authorized;
    }

    /// @notice Get oil metadata
    function getOilMetadata(uint256 tokenId) external view returns (OilMetadata memory) {
        return oilMetadata[tokenId];
    }

    /// @notice Calculate oil value in USD (approximate)
    function getOilValueUSD(uint256 tokenId) external view returns (uint256) {
        return oilMetadata[tokenId].barrelReserves * 80; // $80/barrel approximation
    }

    /// @notice Get daily production value
    function getDailyProductionValueUSD(uint256 tokenId) external view returns (uint256) {
        return oilMetadata[tokenId].dailyProductionCapacity * 80; // Daily revenue estimate
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
    function updateTierPricing(PricingTier tier, uint256 newPrice) external onlyOwner {
        tierPricing[tier] = newPrice;
    }

    /// @notice Withdraw funds
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Check if domain meets ESG standards
    function isESGCompliant(uint256 tokenId) external view returns (bool) {
        return oilMetadata[tokenId].ESGCompliant && 
               (block.timestamp - oilMetadata[tokenId].lastInspectionDate) < 365 days;
    }
}