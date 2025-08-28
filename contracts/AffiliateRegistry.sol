// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Affiliate Registry
/// @notice Tiered affiliate program for Digital Giant domain sales
contract AffiliateRegistry is Ownable, ReentrancyGuard {
    
    enum AffiliateTier { TIER1, TIER2, TIER3 }
    
    struct Affiliate {
        bool isActive;
        AffiliateTier tier;
        uint256 totalSales;      // Total sales volume in USD (wei)
        uint256 totalCommissions; // Total commissions earned
        uint256 referralCount;   // Number of successful referrals
        uint256 joinedTimestamp;
        string referralCode;     // Unique referral code
        address paymentAddress;  // Where to send commissions
    }
    
    struct Sale {
        address buyer;
        address affiliate;
        uint256 saleAmount;     // Sale amount in USD (wei)
        uint256 commission;     // Commission paid
        uint256 timestamp;
        string domainName;
        string tldRegistry;
    }
    
    /// @notice Commission rates by tier (basis points)
    mapping(AffiliateTier => uint256) public tierCommissionBP;
    
    /// @notice Tier thresholds (sales volume required)
    mapping(AffiliateTier => uint256) public tierThresholds;
    
    /// @notice Affiliate data
    mapping(address => Affiliate) public affiliates;
    mapping(string => address) public referralCodeToAffiliate;
    
    /// @notice Sales tracking
    mapping(bytes32 => Sale) public sales;
    mapping(address => bytes32[]) public affiliateSales;
    
    /// @notice Global stats
    uint256 public totalAffiliates;
    uint256 public totalSalesVolume;
    uint256 public totalCommissionsPaid;
    
    /// @notice Supported payment tokens (USDC, USDT)
    mapping(address => bool) public supportedTokens;
    
    /// @notice Payment tracking
    mapping(address => mapping(address => uint256)) public pendingPayments; // affiliate => token => amount
    
    event AffiliateRegistered(address indexed affiliate, string referralCode, AffiliateTier tier);
    event AffiliateTierUpdated(address indexed affiliate, AffiliateTier oldTier, AffiliateTier newTier);
    event SaleRecorded(bytes32 indexed saleId, address indexed affiliate, address indexed buyer, uint256 amount);
    event CommissionPaid(address indexed affiliate, address token, uint256 amount);
    event ReferralCodeGenerated(address indexed affiliate, string code);
    
    constructor(address initialOwner) Ownable(initialOwner) {
        // Set tier commission rates
        tierCommissionBP[AffiliateTier.TIER1] = 500;  // 5%
        tierCommissionBP[AffiliateTier.TIER2] = 700;  // 7%
        tierCommissionBP[AffiliateTier.TIER3] = 1000; // 10%
        
        // Set tier thresholds (in USD wei)
        tierThresholds[AffiliateTier.TIER1] = 0;           // $0 - immediate access
        tierThresholds[AffiliateTier.TIER2] = 10000 ether; // $10,000 sales volume
        tierThresholds[AffiliateTier.TIER3] = 50000 ether; // $50,000 sales volume
        
        // Add supported tokens (Polygon mainnet)
        supportedTokens[0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = true; // USDC
        supportedTokens[0xc2132D05D31c914a87C6611C10748AEb04B58e8F] = true; // USDT
    }
    
    /// @notice Register as affiliate
    function registerAffiliate(string memory preferredCode) external returns (string memory) {
        require(!affiliates[msg.sender].isActive, "Already registered");
        require(bytes(preferredCode).length >= 3 && bytes(preferredCode).length <= 20, "Code length 3-20 chars");
        
        // Generate unique referral code
        string memory referralCode = _generateUniqueCode(preferredCode);
        
        affiliates[msg.sender] = Affiliate({
            isActive: true,
            tier: AffiliateTier.TIER1,
            totalSales: 0,
            totalCommissions: 0,
            referralCount: 0,
            joinedTimestamp: block.timestamp,
            referralCode: referralCode,
            paymentAddress: msg.sender
        });
        
        referralCodeToAffiliate[referralCode] = msg.sender;
        totalAffiliates++;
        
        emit AffiliateRegistered(msg.sender, referralCode, AffiliateTier.TIER1);
        emit ReferralCodeGenerated(msg.sender, referralCode);
        
        return referralCode;
    }
    
    /// @notice Record a sale and calculate commission
    function recordSale(
        address buyer,
        string memory referralCode,
        uint256 saleAmountUSD,
        string memory domainName,
        string memory tldRegistry
    ) external returns (bytes32 saleId) {
        address affiliate = referralCodeToAffiliate[referralCode];
        require(affiliate != address(0), "Invalid referral code");
        require(affiliates[affiliate].isActive, "Affiliate not active");
        require(saleAmountUSD > 0, "Sale amount must be positive");
        
        saleId = keccak256(abi.encodePacked(
            buyer,
            affiliate,
            saleAmountUSD,
            domainName,
            block.timestamp,
            block.number
        ));
        
        // Calculate commission based on current tier
        uint256 commissionAmount = (saleAmountUSD * tierCommissionBP[affiliates[affiliate].tier]) / 10000;
        
        // Record sale
        sales[saleId] = Sale({
            buyer: buyer,
            affiliate: affiliate,
            saleAmount: saleAmountUSD,
            commission: commissionAmount,
            timestamp: block.timestamp,
            domainName: domainName,
            tldRegistry: tldRegistry
        });
        
        // Update affiliate stats
        affiliates[affiliate].totalSales += saleAmountUSD;
        affiliates[affiliate].totalCommissions += commissionAmount;
        affiliates[affiliate].referralCount++;
        
        // Track sale for affiliate
        affiliateSales[affiliate].push(saleId);
        
        // Update global stats
        totalSalesVolume += saleAmountUSD;
        totalCommissionsPaid += commissionAmount;
        
        // Check for tier upgrade
        _updateAffiliateTier(affiliate);
        
        emit SaleRecorded(saleId, affiliate, buyer, saleAmountUSD);
        
        return saleId;
    }
    
    /// @notice Pay commission to affiliate
    function payCommission(
        bytes32 saleId,
        address token,
        uint256 tokenAmount
    ) external onlyOwner {
        require(supportedTokens[token], "Token not supported");
        Sale memory sale = sales[saleId];
        require(sale.affiliate != address(0), "Sale not found");
        
        address affiliate = sale.affiliate;
        address paymentAddress = affiliates[affiliate].paymentAddress;
        
        // Transfer tokens to affiliate
        IERC20(token).transferFrom(msg.sender, paymentAddress, tokenAmount);
        
        emit CommissionPaid(affiliate, token, tokenAmount);
    }
    
    /// @notice Batch pay commissions
    function batchPayCommissions(
        bytes32[] calldata saleIds,
        address token,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(saleIds.length == amounts.length, "Array length mismatch");
        require(supportedTokens[token], "Token not supported");
        
        for (uint256 i = 0; i < saleIds.length; i++) {
            Sale memory sale = sales[saleIds[i]];
            if (sale.affiliate != address(0)) {
                address paymentAddress = affiliates[sale.affiliate].paymentAddress;
                IERC20(token).transferFrom(msg.sender, paymentAddress, amounts[i]);
                emit CommissionPaid(sale.affiliate, token, amounts[i]);
            }
        }
    }
    
    /// @notice Update affiliate tier based on sales volume
    function _updateAffiliateTier(address affiliate) internal {
        Affiliate storage aff = affiliates[affiliate];
        AffiliateTier oldTier = aff.tier;
        AffiliateTier newTier = oldTier;
        
        if (aff.totalSales >= tierThresholds[AffiliateTier.TIER3]) {
            newTier = AffiliateTier.TIER3;
        } else if (aff.totalSales >= tierThresholds[AffiliateTier.TIER2]) {
            newTier = AffiliateTier.TIER2;
        } else {
            newTier = AffiliateTier.TIER1;
        }
        
        if (newTier != oldTier) {
            aff.tier = newTier;
            emit AffiliateTierUpdated(affiliate, oldTier, newTier);
        }
    }
    
    /// @notice Generate unique referral code
    function _generateUniqueCode(string memory preferred) internal view returns (string memory) {
        string memory baseCode = _sanitizeCode(preferred);
        
        // Check if preferred code is available
        if (referralCodeToAffiliate[baseCode] == address(0)) {
            return baseCode;
        }
        
        // Generate variations
        for (uint256 i = 1; i <= 999; i++) {
            string memory candidate = string(abi.encodePacked(baseCode, Strings.toString(i)));
            if (referralCodeToAffiliate[candidate] == address(0)) {
                return candidate;
            }
        }
        
        // Fallback to address-based code
        return string(abi.encodePacked("DG", Strings.toHexString(uint160(msg.sender), 20)));
    }
    
    /// @notice Sanitize referral code
    function _sanitizeCode(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        bytes memory output = new bytes(inputBytes.length);
        uint256 outputLength = 0;
        
        for (uint256 i = 0; i < inputBytes.length; i++) {
            bytes1 char = inputBytes[i];
            // Allow alphanumeric characters
            if ((char >= 0x30 && char <= 0x39) || // 0-9
                (char >= 0x41 && char <= 0x5A) || // A-Z
                (char >= 0x61 && char <= 0x7A)) { // a-z
                output[outputLength] = char;
                outputLength++;
            }
        }
        
        // Trim output to actual length
        bytes memory trimmed = new bytes(outputLength);
        for (uint256 i = 0; i < outputLength; i++) {
            trimmed[i] = output[i];
        }
        
        return string(trimmed);
    }
    
    /// @notice Get affiliate data
    function getAffiliate(address affiliate) external view returns (Affiliate memory) {
        return affiliates[affiliate];
    }
    
    /// @notice Get affiliate by referral code
    function getAffiliateByCode(string memory referralCode) external view returns (address, Affiliate memory) {
        address affiliate = referralCodeToAffiliate[referralCode];
        return (affiliate, affiliates[affiliate]);
    }
    
    /// @notice Get affiliate sales
    function getAffiliateSales(address affiliate) external view returns (bytes32[] memory) {
        return affiliateSales[affiliate];
    }
    
    /// @notice Get sale details
    function getSale(bytes32 saleId) external view returns (Sale memory) {
        return sales[saleId];
    }
    
    /// @notice Get commission rate for affiliate
    function getCommissionRate(address affiliate) external view returns (uint256) {
        if (!affiliates[affiliate].isActive) return 0;
        return tierCommissionBP[affiliates[affiliate].tier];
    }
    
    /// @notice Update payment address
    function updatePaymentAddress(address newPaymentAddress) external {
        require(affiliates[msg.sender].isActive, "Not an affiliate");
        require(newPaymentAddress != address(0), "Invalid address");
        affiliates[msg.sender].paymentAddress = newPaymentAddress;
    }
    
    /// @notice Admin functions
    function addSupportedToken(address token) external onlyOwner {
        supportedTokens[token] = true;
    }
    
    function updateTierCommission(AffiliateTier tier, uint256 commissionBP) external onlyOwner {
        require(commissionBP <= 2000, "Commission too high"); // Max 20%
        tierCommissionBP[tier] = commissionBP;
    }
    
    function updateTierThreshold(AffiliateTier tier, uint256 threshold) external onlyOwner {
        tierThresholds[tier] = threshold;
    }
    
    /// @notice Deactivate affiliate
    function deactivateAffiliate(address affiliate) external onlyOwner {
        affiliates[affiliate].isActive = false;
    }
    
    /// @notice Emergency withdraw
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).transfer(owner(), amount);
        }
    }
}