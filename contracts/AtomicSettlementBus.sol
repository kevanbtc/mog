// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title Atomic Settlement Bus
/// @notice PvP/DvP settlement engine for Digital Giant domain transactions
contract AtomicSettlementBus is Ownable, ReentrancyGuard, Pausable {
    
    /// @notice Supported stablecoins for payments
    mapping(address => bool) public supportedStablecoins;
    mapping(address => string) public stablecoinSymbols;
    
    /// @notice Supported TLD registries
    mapping(address => bool) public supportedRegistries;
    mapping(address => string) public registryNames;
    
    /// @notice Settlement fee (basis points)
    uint256 public settlementFeeBP = 25; // 0.25%
    
    /// @notice Treasury for collecting fees
    address public treasury;
    
    /// @notice Affiliate program
    mapping(address => bool) public affiliates;
    mapping(address => uint256) public affiliateCommissionBP; // Basis points
    mapping(address => uint256) public affiliateEarnings;
    mapping(address => address) public affiliateReferrals; // buyer => affiliate
    
    struct Settlement {
        address buyer;
        address seller;
        address registry;
        uint256 tokenId;
        address stablecoin;
        uint256 amount;
        uint256 settlementFee;
        uint256 affiliateCommission;
        address affiliate;
        bool completed;
        uint256 timestamp;
    }
    
    mapping(bytes32 => Settlement) public settlements;
    
    event StablecoinAdded(address indexed token, string symbol);
    event RegistryAdded(address indexed registry, string name);
    event SettlementInitiated(bytes32 indexed settlementId, address buyer, address seller, uint256 amount);
    event SettlementCompleted(bytes32 indexed settlementId, uint256 totalPaid, uint256 fees);
    event AffiliateRegistered(address indexed affiliate, uint256 commissionBP);
    event AffiliateCommissionPaid(address indexed affiliate, uint256 amount);
    event ISO20022Settlement(bytes32 indexed settlementId, string messageType, string transactionId);
    
    constructor(address initialOwner, address _treasury) 
        Ownable(initialOwner) 
    {
        treasury = _treasury;
        
        // Add USDC on Polygon
        _addStablecoin(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, "USDC");
        // Add USDT on Polygon  
        _addStablecoin(0xc2132D05D31c914a87C6611C10748AEb04B58e8F, "USDT");
    }
    
    /// @notice Add supported stablecoin
    function addStablecoin(address token, string memory symbol) external onlyOwner {
        _addStablecoin(token, symbol);
    }
    
    function _addStablecoin(address token, string memory symbol) internal {
        supportedStablecoins[token] = true;
        stablecoinSymbols[token] = symbol;
        emit StablecoinAdded(token, symbol);
    }
    
    /// @notice Add supported TLD registry
    function addRegistry(address registry, string memory name) external onlyOwner {
        supportedRegistries[registry] = true;
        registryNames[registry] = name;
        emit RegistryAdded(registry, name);
    }
    
    /// @notice Register as affiliate
    function registerAffiliate(address affiliate, uint256 commissionBP) external onlyOwner {
        require(commissionBP <= 1000, "Commission too high"); // Max 10%
        affiliates[affiliate] = true;
        affiliateCommissionBP[affiliate] = commissionBP;
        emit AffiliateRegistered(affiliate, commissionBP);
    }
    
    /// @notice Atomic domain purchase with stablecoin
    function purchaseDomainAtomic(
        address registry,
        address stablecoin,
        uint256 amount,
        address affiliate,
        bytes calldata mintCalldata
    ) external nonReentrant whenNotPaused returns (bytes32 settlementId) {
        require(supportedStablecoins[stablecoin], "Stablecoin not supported");
        require(supportedRegistries[registry], "Registry not supported");
        require(amount > 0, "Amount must be positive");
        
        // Generate settlement ID
        settlementId = keccak256(abi.encodePacked(
            msg.sender,
            registry,
            stablecoin,
            amount,
            block.timestamp,
            block.number
        ));
        
        // Calculate fees
        uint256 settlementFee = (amount * settlementFeeBP) / 10000;
        uint256 affiliateCommission = 0;
        
        if (affiliate != address(0) && affiliates[affiliate]) {
            affiliateCommission = (amount * affiliateCommissionBP[affiliate]) / 10000;
            affiliateReferrals[msg.sender] = affiliate;
        }
        
        uint256 totalRequired = amount + settlementFee;
        
        // Transfer stablecoin from buyer
        IERC20(stablecoin).transferFrom(msg.sender, address(this), totalRequired);
        
        // Execute mint call on registry
        (bool success, bytes memory result) = registry.call(mintCalldata);
        require(success, "Registry mint failed");
        
        // Extract token ID from mint result (assume first return value)
        uint256 tokenId = abi.decode(result, (uint256));
        
        // Create settlement record
        settlements[settlementId] = Settlement({
            buyer: msg.sender,
            seller: registry,
            registry: registry,
            tokenId: tokenId,
            stablecoin: stablecoin,
            amount: amount,
            settlementFee: settlementFee,
            affiliateCommission: affiliateCommission,
            affiliate: affiliate,
            completed: true,
            timestamp: block.timestamp
        });
        
        // Transfer payment to registry (minus fees)
        uint256 netAmount = amount - affiliateCommission;
        IERC20(stablecoin).transfer(registry, netAmount);
        
        // Pay affiliate commission
        if (affiliateCommission > 0) {
            IERC20(stablecoin).transfer(affiliate, affiliateCommission);
            affiliateEarnings[affiliate] += affiliateCommission;
            emit AffiliateCommissionPaid(affiliate, affiliateCommission);
        }
        
        // Pay settlement fee to treasury
        IERC20(stablecoin).transfer(treasury, settlementFee);
        
        emit SettlementInitiated(settlementId, msg.sender, registry, amount);
        emit SettlementCompleted(settlementId, totalRequired, settlementFee + affiliateCommission);
        emit ISO20022Settlement(settlementId, "pacs.008.001.12", _generateTransactionId(settlementId));
        
        return settlementId;
    }
    
    /// @notice Purchase domain with ETH/MATIC (auto-convert via DEX)
    function purchaseDomainWithETH(
        address registry,
        address affiliate,
        bytes calldata mintCalldata
    ) external payable nonReentrant whenNotPaused returns (bytes32 settlementId) {
        require(msg.value > 0, "Must send ETH");
        require(supportedRegistries[registry], "Registry not supported");
        
        // For simplicity, accept ETH directly and let registry handle conversion
        // In production, integrate with DEX for ETH->USDC swap
        
        settlementId = keccak256(abi.encodePacked(
            msg.sender,
            registry,
            address(0), // ETH
            msg.value,
            block.timestamp,
            block.number
        ));
        
        // Calculate fees
        uint256 settlementFee = (msg.value * settlementFeeBP) / 10000;
        uint256 affiliateCommission = 0;
        
        if (affiliate != address(0) && affiliates[affiliate]) {
            affiliateCommission = (msg.value * affiliateCommissionBP[affiliate]) / 10000;
            affiliateReferrals[msg.sender] = affiliate;
        }
        
        // Execute mint call on registry with ETH
        uint256 netAmount = msg.value - settlementFee - affiliateCommission;
        (bool success, bytes memory result) = registry.call{value: netAmount}(mintCalldata);
        require(success, "Registry mint failed");
        
        uint256 tokenId = abi.decode(result, (uint256));
        
        settlements[settlementId] = Settlement({
            buyer: msg.sender,
            seller: registry,
            registry: registry,
            tokenId: tokenId,
            stablecoin: address(0), // ETH
            amount: msg.value,
            settlementFee: settlementFee,
            affiliateCommission: affiliateCommission,
            affiliate: affiliate,
            completed: true,
            timestamp: block.timestamp
        });
        
        // Pay affiliate commission
        if (affiliateCommission > 0) {
            payable(affiliate).transfer(affiliateCommission);
            affiliateEarnings[affiliate] += affiliateCommission;
            emit AffiliateCommissionPaid(affiliate, affiliateCommission);
        }
        
        // Pay settlement fee to treasury
        payable(treasury).transfer(settlementFee);
        
        emit SettlementInitiated(settlementId, msg.sender, registry, msg.value);
        emit SettlementCompleted(settlementId, msg.value, settlementFee + affiliateCommission);
        emit ISO20022Settlement(settlementId, "pacs.008.001.12", _generateTransactionId(settlementId));
        
        return settlementId;
    }
    
    /// @notice PvP settlement between two stablecoins
    function settlePvP(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address counterparty
    ) external nonReentrant whenNotPaused returns (bytes32 settlementId) {
        require(supportedStablecoins[tokenA], "TokenA not supported");
        require(supportedStablecoins[tokenB], "TokenB not supported");
        require(counterparty != msg.sender, "Cannot settle with self");
        
        settlementId = keccak256(abi.encodePacked(
            msg.sender,
            counterparty,
            tokenA,
            tokenB,
            amountA,
            amountB,
            block.timestamp
        ));
        
        // Calculate settlement fees
        uint256 feeA = (amountA * settlementFeeBP) / 10000;
        uint256 feeB = (amountB * settlementFeeBP) / 10000;
        
        // Atomic swap
        IERC20(tokenA).transferFrom(msg.sender, counterparty, amountA - feeA);
        IERC20(tokenB).transferFrom(counterparty, msg.sender, amountB - feeB);
        
        // Collect fees
        IERC20(tokenA).transferFrom(msg.sender, treasury, feeA);
        IERC20(tokenB).transferFrom(counterparty, treasury, feeB);
        
        emit ISO20022Settlement(settlementId, "pacs.009.001.08", _generateTransactionId(settlementId));
        
        return settlementId;
    }
    
    /// @notice Get settlement details
    function getSettlement(bytes32 settlementId) external view returns (Settlement memory) {
        return settlements[settlementId];
    }
    
    /// @notice Get affiliate earnings
    function getAffiliateEarnings(address affiliate) external view returns (uint256) {
        return affiliateEarnings[affiliate];
    }
    
    /// @notice Update settlement fee
    function setSettlementFee(uint256 newFeeBP) external onlyOwner {
        require(newFeeBP <= 500, "Fee too high"); // Max 5%
        settlementFeeBP = newFeeBP;
    }
    
    /// @notice Update treasury
    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }
    
    /// @notice Emergency pause
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /// @notice Emergency withdrawal
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).transfer(owner(), amount);
        }
    }
    
    /// @notice Generate transaction ID for ISO 20022
    function _generateTransactionId(bytes32 settlementId) internal view returns (string memory) {
        return string(abi.encodePacked(
            "DG-",
            Strings.toString(block.chainid),
            "-",
            Strings.toString(block.timestamp),
            "-",
            Strings.toHexString(uint256(settlementId))
        ));
    }
}

// Import required for Strings utility
import "@openzeppelin/contracts/utils/Strings.sol";