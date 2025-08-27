// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Real Estate TLD Registry
/// @notice Premium real estate domain registry with RWA tokenization integration
contract RealTLD is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextDomainId;
    
    /// @notice Real estate property types
    enum PropertyType { 
        RESIDENTIAL, 
        COMMERCIAL, 
        INDUSTRIAL, 
        RETAIL, 
        HOSPITALITY, 
        MIXED_USE,
        REIT,
        FRACTIONAL_OWNERSHIP
    }
    
    enum PricingTier { STANDARD, PREMIUM, ULTRA_PREMIUM, ENTERPRISE }
    
    /// @notice Real estate-specific metadata
    struct RealEstateMetadata {
        PropertyType propertyType;
        PricingTier pricingTier;
        uint256 propertyValueUSD; // Property valuation in USD
        string propertyAddress; // Physical property address
        uint256 squareFootage; // Total square footage
        bool titleVerified; // Title verification status
        string titleCompanyIPFS; // Title company verification docs
        uint256 lastAppraisalDate;
        bool fractionalOwnership; // Supports fractional NFT ownership
        uint256 annualRentalIncome; // Expected annual rental income
        string regulatoryZoning; // Zoning classification
    }
    
    /// @notice Domain mappings
    mapping(string => uint256) public domainToTokenId;
    mapping(uint256 => string) public tokenIdToDomain;
    mapping(string => address) public domainResolution;
    mapping(address => string) public reverseResolution;
    mapping(uint256 => address) public domainVaults;
    mapping(uint256 => RealEstateMetadata) public realEstateMetadata;
    
    /// @notice Pricing structure (in wei)
    mapping(PricingTier => uint256) public tierPricing;
    
    /// @notice Authorized real estate verifiers
    mapping(address => bool) public authorizedVerifiers;
    
    /// @notice Property fractional ownership tracking
    mapping(uint256 => mapping(address => uint256)) public fractionalOwnership;
    mapping(uint256 => uint256) public totalFractionalShares;
    
    event RealEstateDomainMinted(uint256 indexed tokenId, string indexed domainName, address indexed to, PropertyType propertyType);
    event PropertyValuationUpdated(uint256 indexed tokenId, uint256 oldValue, uint256 newValue);
    event TitleVerification(uint256 indexed tokenId, address verifier, string titleCompanyIPFS);
    event ISO20022RealEstateMessage(uint256 indexed tokenId, string messageType, uint256 propertyValue);
    event FractionalOwnershipCreated(uint256 indexed tokenId, uint256 totalShares, uint256 sharePrice);
    event RentalIncomeUpdated(uint256 indexed tokenId, uint256 annualIncome);

    constructor(address initialOwner) 
        ERC721("Real Estate Digital Naming Service", "REAL") 
        Ownable(initialOwner) 
    {
        // Ultra-premium real estate pricing
        tierPricing[PricingTier.STANDARD] = 0.1 ether;       // ~$250
        tierPricing[PricingTier.PREMIUM] = 1 ether;          // ~$2,500
        tierPricing[PricingTier.ULTRA_PREMIUM] = 10 ether;   // ~$25,000
        tierPricing[PricingTier.ENTERPRISE] = 50 ether;      // ~$125,000
    }

    /// @notice Mint real estate domain with property backing
    function mintRealEstateDomain(
        address to,
        string memory domainName,
        string memory ipfsCID,
        PropertyType propertyType,
        PricingTier pricingTier,
        uint256 propertyValueUSD,
        string memory propertyAddress,
        uint256 squareFootage,
        string memory regulatoryZoning
    ) external payable onlyOwner nonReentrant {
        require(bytes(domainName).length > 0, "Domain name cannot be empty");
        require(domainToTokenId[domainName] == 0, "Domain already exists");
        require(msg.value >= tierPricing[pricingTier], "Insufficient payment");
        require(propertyValueUSD > 0, "Property value must be positive");
        
        uint256 tokenId = ++nextDomainId;
        
        // Standard domain setup
        domainToTokenId[domainName] = tokenId;
        tokenIdToDomain[tokenId] = domainName;
        domainResolution[domainName] = to;
        
        // Real estate-specific metadata
        realEstateMetadata[tokenId] = RealEstateMetadata({
            propertyType: propertyType,
            pricingTier: pricingTier,
            propertyValueUSD: propertyValueUSD,
            propertyAddress: propertyAddress,
            squareFootage: squareFootage,
            titleVerified: false, // Requires verification
            titleCompanyIPFS: ipfsCID,
            lastAppraisalDate: block.timestamp,
            fractionalOwnership: false,
            annualRentalIncome: 0,
            regulatoryZoning: regulatoryZoning
        });
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", ipfsCID)));
        
        emit RealEstateDomainMinted(tokenId, domainName, to, propertyType);
        emit ISO20022RealEstateMessage(tokenId, "pacs.008.001.12", propertyValueUSD);
        
        // Refund excess
        if (msg.value > tierPricing[pricingTier]) {
            payable(msg.sender).transfer(msg.value - tierPricing[pricingTier]);
        }
    }

    /// @notice Update property valuation and rental income
    function updatePropertyValuation(
        uint256 tokenId,
        uint256 newValueUSD,
        uint256 annualRentalIncome,
        string memory appraisalReportIPFS
    ) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        uint256 oldValue = realEstateMetadata[tokenId].propertyValueUSD;
        realEstateMetadata[tokenId].propertyValueUSD = newValueUSD;
        realEstateMetadata[tokenId].annualRentalIncome = annualRentalIncome;
        realEstateMetadata[tokenId].lastAppraisalDate = block.timestamp;
        realEstateMetadata[tokenId].titleCompanyIPFS = appraisalReportIPFS;
        
        emit PropertyValuationUpdated(tokenId, oldValue, newValueUSD);
        emit RentalIncomeUpdated(tokenId, annualRentalIncome);
    }

    /// @notice Verify property title (authorized verifiers only)
    function verifyTitle(
        uint256 tokenId,
        string memory titleCompanyIPFS
    ) external {
        require(authorizedVerifiers[msg.sender], "Not authorized verifier");
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        realEstateMetadata[tokenId].titleVerified = true;
        realEstateMetadata[tokenId].titleCompanyIPFS = titleCompanyIPFS;
        
        emit TitleVerification(tokenId, msg.sender, titleCompanyIPFS);
    }

    /// @notice Enable fractional ownership for property
    function enableFractionalOwnership(
        uint256 tokenId,
        uint256 totalShares,
        uint256 sharePrice
    ) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(!realEstateMetadata[tokenId].fractionalOwnership, "Already fractional");
        
        realEstateMetadata[tokenId].fractionalOwnership = true;
        totalFractionalShares[tokenId] = totalShares;
        
        emit FractionalOwnershipCreated(tokenId, totalShares, sharePrice);
    }

    /// @notice Purchase fractional ownership shares
    function purchaseFractionalShares(
        uint256 tokenId,
        uint256 shares
    ) external payable nonReentrant {
        require(realEstateMetadata[tokenId].fractionalOwnership, "Not fractional property");
        require(shares > 0, "Shares must be positive");
        
        // Calculate required payment (simplified pricing model)
        uint256 sharePrice = realEstateMetadata[tokenId].propertyValueUSD / totalFractionalShares[tokenId];
        require(msg.value >= sharePrice * shares, "Insufficient payment");
        
        fractionalOwnership[tokenId][msg.sender] += shares;
        
        // Refund excess
        if (msg.value > sharePrice * shares) {
            payable(msg.sender).transfer(msg.value - (sharePrice * shares));
        }
    }

    /// @notice Authorize title/property verifiers
    function setAuthorizedVerifier(address verifier, bool authorized) external onlyOwner {
        authorizedVerifiers[verifier] = authorized;
    }

    /// @notice Get real estate metadata
    function getRealEstateMetadata(uint256 tokenId) external view returns (RealEstateMetadata memory) {
        return realEstateMetadata[tokenId];
    }

    /// @notice Calculate property yield percentage (annual rental / property value)
    function getPropertyYield(uint256 tokenId) external view returns (uint256) {
        RealEstateMetadata memory metadata = realEstateMetadata[tokenId];
        if (metadata.propertyValueUSD == 0) return 0;
        return (metadata.annualRentalIncome * 10000) / metadata.propertyValueUSD; // Basis points
    }

    /// @notice Get fractional ownership information
    function getFractionalOwnership(uint256 tokenId, address owner) external view returns (uint256) {
        return fractionalOwnership[tokenId][owner];
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

    /// @notice Check if property meets investment criteria
    function isInvestmentGrade(uint256 tokenId) external view returns (bool) {
        RealEstateMetadata memory metadata = realEstateMetadata[tokenId];
        return metadata.titleVerified && 
               metadata.propertyValueUSD >= 100000 && // Minimum $100K value
               (block.timestamp - metadata.lastAppraisalDate) < 365 days; // Recent appraisal
    }
}