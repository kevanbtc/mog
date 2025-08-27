// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Gold TLD Registry
/// @notice Premium precious metals domain registry with commodity integration
contract GoldTLD is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 public nextDomainId;
    
    /// @notice Premium pricing tiers
    enum PricingTier { STANDARD, PREMIUM, ULTRA_PREMIUM }
    
    /// @notice Gold-specific metadata
    struct GoldMetadata {
        PricingTier pricingTier;
        uint256 goldBackingOunces; // Physical gold backing in ounces
        string vaultLocation; // Physical vault location
        bool auditVerified; // Third-party audit status
        uint256 lastAuditDate;
        string certificateIPFS; // Precious metals certificate
    }
    
    /// @notice Domain name to token ID mapping
    mapping(string => uint256) public domainToTokenId;
    /// @notice Token ID to domain name mapping  
    mapping(uint256 => string) public tokenIdToDomain;
    /// @notice Domain resolution mapping
    mapping(string => address) public domainResolution;
    /// @notice Reverse resolution mapping
    mapping(address => string) public reverseResolution;
    /// @notice ERC-6551 vault addresses
    mapping(uint256 => address) public domainVaults;
    /// @notice Gold-specific metadata
    mapping(uint256 => GoldMetadata) public goldMetadata;
    
    /// @notice Pricing for different tiers (in wei)
    mapping(PricingTier => uint256) public tierPricing;
    
    event GoldDomainMinted(uint256 indexed tokenId, string indexed domainName, address indexed to, PricingTier tier);
    event GoldBackingUpdated(uint256 indexed tokenId, uint256 goldOunces, string vaultLocation);
    event AuditCompleted(uint256 indexed tokenId, address auditor, string reportIPFS);
    event ISO20022GoldMessage(uint256 indexed tokenId, string messageType, uint256 goldValue);

    constructor(address initialOwner) 
        ERC721("Gold Digital Naming Service", "GOLD") 
        Ownable(initialOwner) 
    {
        // Set premium pricing for gold domains
        tierPricing[PricingTier.STANDARD] = 0.01 ether;      // ~$25
        tierPricing[PricingTier.PREMIUM] = 0.1 ether;        // ~$250  
        tierPricing[PricingTier.ULTRA_PREMIUM] = 1 ether;    // ~$2500
    }

    /// @notice Mint a gold domain with precious metals backing
    function mintGoldDomain(
        address to,
        string memory domainName,
        string memory ipfsCID,
        PricingTier tier,
        uint256 goldOunces,
        string memory vaultLocation
    ) external payable onlyOwner nonReentrant {
        require(bytes(domainName).length > 0, "Domain name cannot be empty");
        require(domainToTokenId[domainName] == 0, "Domain already exists");
        require(msg.value >= tierPricing[tier], "Insufficient payment");
        
        uint256 tokenId = ++nextDomainId;
        
        // Standard domain setup
        domainToTokenId[domainName] = tokenId;
        tokenIdToDomain[tokenId] = domainName;
        domainResolution[domainName] = to;
        
        // Gold-specific metadata
        goldMetadata[tokenId] = GoldMetadata({
            pricingTier: tier,
            goldBackingOunces: goldOunces,
            vaultLocation: vaultLocation,
            auditVerified: false,
            lastAuditDate: 0,
            certificateIPFS: ipfsCID
        });
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", ipfsCID)));
        
        emit GoldDomainMinted(tokenId, domainName, to, tier);
        emit ISO20022GoldMessage(tokenId, "pacs.008.001.12", goldOunces * 2000); // Approx $2000/oz
        
        // Refund excess payment
        if (msg.value > tierPricing[tier]) {
            payable(msg.sender).transfer(msg.value - tierPricing[tier]);
        }
    }

    /// @notice Update gold backing for a domain
    function updateGoldBacking(
        uint256 tokenId,
        uint256 goldOunces,
        string memory vaultLocation,
        string memory auditReport
    ) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        goldMetadata[tokenId].goldBackingOunces = goldOunces;
        goldMetadata[tokenId].vaultLocation = vaultLocation;
        goldMetadata[tokenId].lastAuditDate = block.timestamp;
        goldMetadata[tokenId].auditVerified = true;
        goldMetadata[tokenId].certificateIPFS = auditReport;
        
        emit GoldBackingUpdated(tokenId, goldOunces, vaultLocation);
        emit AuditCompleted(tokenId, msg.sender, auditReport);
    }

    /// @notice Get gold metadata for a domain
    function getGoldMetadata(uint256 tokenId) external view returns (GoldMetadata memory) {
        return goldMetadata[tokenId];
    }

    /// @notice Calculate gold value in USD (approximate)
    function getGoldValueUSD(uint256 tokenId) external view returns (uint256) {
        return goldMetadata[tokenId].goldBackingOunces * 2000; // $2000/oz approximation
    }

    /// @notice Resolve domain name
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
    }

    /// @notice Bind ERC-6551 vault to domain
    function bindVault(uint256 tokenId, address vaultAddress) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        domainVaults[tokenId] = vaultAddress;
    }

    /// @notice Update pricing tiers
    function updateTierPricing(PricingTier tier, uint256 newPrice) external onlyOwner {
        tierPricing[tier] = newPrice;
    }

    /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Enhanced tokenURI with gold metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        string memory baseURI = super.tokenURI(tokenId);
        GoldMetadata memory metadata = goldMetadata[tokenId];
        
        // Could enhance with on-chain metadata generation
        return baseURI;
    }
}