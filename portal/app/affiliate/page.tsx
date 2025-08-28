'use client';

import { useState, useEffect } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { useAccount, useReadContract, useWriteContract } from 'wagmi';

export default function AffiliatePage() {
  const { address, isConnected } = useAccount();
  const [referralCode, setReferralCode] = useState('');
  const [preferredCode, setPreferredCode] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [affiliateData, setAffiliateData] = useState(null);
  
  // Mock contract address - replace with actual deployed address
  const AFFILIATE_REGISTRY_ADDRESS = "0x..." as `0x${string}`;

  const { data: affiliateInfo } = useReadContract({
    address: AFFILIATE_REGISTRY_ADDRESS,
    abi: [
      {
        "inputs": [{"name": "affiliate", "type": "address"}],
        "name": "getAffiliate",
        "outputs": [
          {"name": "isActive", "type": "bool"},
          {"name": "tier", "type": "uint8"},
          {"name": "totalSales", "type": "uint256"},
          {"name": "totalCommissions", "type": "uint256"},
          {"name": "referralCount", "type": "uint256"},
          {"name": "referralCode", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
      }
    ],
    functionName: 'getAffiliate',
    args: [address || "0x0000000000000000000000000000000000000000"]
  });

  const { writeContract } = useWriteContract();

  useEffect(() => {
    if (affiliateInfo && affiliateInfo[0]) { // isActive = true
      setAffiliateData({
        isActive: affiliateInfo[0],
        tier: affiliateInfo[1],
        totalSales: affiliateInfo[2],
        totalCommissions: affiliateInfo[3],
        referralCount: affiliateInfo[4],
        referralCode: affiliateInfo[5]
      });
      setReferralCode(affiliateInfo[5]);
    }
  }, [affiliateInfo]);

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isConnected || !preferredCode.trim()) return;

    setIsLoading(true);
    try {
      await writeContract({
        address: AFFILIATE_REGISTRY_ADDRESS,
        abi: [
          {
            "inputs": [{"name": "preferredCode", "type": "string"}],
            "name": "registerAffiliate",
            "outputs": [{"name": "", "type": "string"}],
            "stateMutability": "nonpayable",
            "type": "function"
          }
        ],
        functionName: 'registerAffiliate',
        args: [preferredCode]
      });
      
      // Refresh data after registration
      setTimeout(() => window.location.reload(), 2000);
    } catch (error) {
      console.error('Registration failed:', error);
      alert('Registration failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const copyReferralLink = () => {
    const link = `${window.location.origin}/mint?ref=${referralCode}`;
    navigator.clipboard.writeText(link);
    alert('Referral link copied to clipboard!');
  };

  const getTierName = (tier: number) => {
    switch (tier) {
      case 0: return 'Tier 1 (5%)';
      case 1: return 'Tier 2 (7%)';
      case 2: return 'Tier 3 (10%)';
      default: return 'Unknown';
    }
  };

  const getTierColor = (tier: number) => {
    switch (tier) {
      case 0: return 'text-blue-400';
      case 1: return 'text-purple-400';
      case 2: return 'text-gold-400';
      default: return 'text-gray-400';
    }
  };

  return (
    <main className="min-h-screen">
      {/* Navigation */}
      <nav className="relative z-20 flex justify-between items-center p-6 glass-morphism">
        <Link href="/" className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg"></div>
          <h1 className="text-2xl font-bold text-white font-mono">Digital Giant</h1>
          <span className="text-xs bg-purple-600 text-white px-2 py-1 rounded-full">AFFILIATE</span>
        </Link>
        
        <div className="hidden md:flex space-x-6 text-white">
          <Link href="/" className="hover:text-blue-400 transition-colors">Home</Link>
          <Link href="/mint" className="hover:text-blue-400 transition-colors">Mint</Link>
          <Link href="/dashboard" className="hover:text-blue-400 transition-colors">Dashboard</Link>
        </div>

        <ConnectButton />
      </nav>

      {/* Main Content */}
      <div className="max-w-6xl mx-auto px-6 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-white mb-4">
            Digital Giant <span className="bg-gradient-to-r from-green-400 to-blue-500 bg-clip-text text-transparent">Affiliate Program</span>
          </h1>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Earn up to 10% commission on enterprise domain sales. Get paid in USDC for every referral.
          </p>
        </div>

        {!isConnected ? (
          /* Connect Wallet Prompt */
          <div className="text-center">
            <div className="glass-morphism p-12 rounded-2xl border border-white/20 max-w-md mx-auto">
              <div className="text-6xl mb-4">🤝</div>
              <h2 className="text-2xl font-bold text-white mb-4">Connect Wallet</h2>
              <p className="text-gray-300 mb-6">Connect your wallet to join the affiliate program</p>
              <ConnectButton />
            </div>
          </div>
        ) : affiliateData?.isActive ? (
          /* Affiliate Dashboard */
          <div className="space-y-8">
            {/* Stats Overview */}
            <div className="grid md:grid-cols-4 gap-6">
              <div className="glass-morphism p-6 rounded-2xl border border-white/20">
                <div className="text-2xl mb-2">🏆</div>
                <h3 className="text-white font-semibold mb-1">Current Tier</h3>
                <p className={`text-lg font-bold ${getTierColor(affiliateData.tier)}`}>
                  {getTierName(affiliateData.tier)}
                </p>
              </div>
              <div className="glass-morphism p-6 rounded-2xl border border-white/20">
                <div className="text-2xl mb-2">💰</div>
                <h3 className="text-white font-semibold mb-1">Total Sales</h3>
                <p className="text-lg font-bold text-green-400">
                  ${(Number(affiliateData.totalSales || 0) / 1e18).toLocaleString()}
                </p>
              </div>
              <div className="glass-morphism p-6 rounded-2xl border border-white/20">
                <div className="text-2xl mb-2">🎯</div>
                <h3 className="text-white font-semibold mb-1">Referrals</h3>
                <p className="text-lg font-bold text-blue-400">
                  {affiliateData.referralCount?.toString() || '0'}
                </p>
              </div>
              <div className="glass-morphism p-6 rounded-2xl border border-white/20">
                <div className="text-2xl mb-2">💎</div>
                <h3 className="text-white font-semibold mb-1">Commissions</h3>
                <p className="text-lg font-bold text-purple-400">
                  ${(Number(affiliateData.totalCommissions || 0) / 1e18).toLocaleString()}
                </p>
              </div>
            </div>

            {/* Referral Link */}
            <div className="glass-morphism p-8 rounded-2xl border border-white/20">
              <h2 className="text-2xl font-bold text-white mb-4">Your Referral Link</h2>
              <div className="flex flex-col md:flex-row gap-4">
                <div className="flex-1">
                  <input
                    type="text"
                    value={`${typeof window !== 'undefined' ? window.location.origin : ''}/mint?ref=${referralCode}`}
                    readOnly
                    className="w-full bg-black/40 text-white border border-white/20 rounded-xl px-4 py-3 font-mono text-sm"
                  />
                </div>
                <button
                  onClick={copyReferralLink}
                  className="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-6 py-3 rounded-xl font-semibold hover:from-blue-600 hover:to-purple-700 transition-all"
                >
                  📋 Copy Link
                </button>
              </div>
              <div className="mt-4 grid md:grid-cols-2 gap-4 text-sm text-gray-300">
                <div>
                  <p><strong>Your Code:</strong> <span className="text-blue-400 font-mono">{referralCode}</span></p>
                </div>
                <div>
                  <p><strong>Commission Rate:</strong> <span className="text-green-400">{affiliateData.tier === 0 ? '5%' : affiliateData.tier === 1 ? '7%' : '10%'}</span></p>
                </div>
              </div>
            </div>

            {/* Tier Progression */}
            <div className="glass-morphism p-8 rounded-2xl border border-white/20">
              <h2 className="text-2xl font-bold text-white mb-6">Tier Progression</h2>
              <div className="space-y-4">
                <div className="flex items-center justify-between p-4 rounded-xl bg-gradient-to-r from-blue-500/20 to-blue-600/20 border border-blue-400/30">
                  <div>
                    <h3 className="text-white font-semibold">Tier 1 - 5% Commission</h3>
                    <p className="text-sm text-gray-300">$0+ sales volume</p>
                  </div>
                  <div className="text-blue-400">
                    {affiliateData.tier >= 0 ? '✅' : '🔒'}
                  </div>
                </div>
                <div className="flex items-center justify-between p-4 rounded-xl bg-gradient-to-r from-purple-500/20 to-purple-600/20 border border-purple-400/30">
                  <div>
                    <h3 className="text-white font-semibold">Tier 2 - 7% Commission</h3>
                    <p className="text-sm text-gray-300">$10,000+ sales volume</p>
                  </div>
                  <div className="text-purple-400">
                    {affiliateData.tier >= 1 ? '✅' : '🔒'}
                  </div>
                </div>
                <div className="flex items-center justify-between p-4 rounded-xl bg-gradient-to-r from-gold-500/20 to-yellow-600/20 border border-yellow-400/30">
                  <div>
                    <h3 className="text-white font-semibold">Tier 3 - 10% Commission</h3>
                    <p className="text-sm text-gray-300">$50,000+ sales volume</p>
                  </div>
                  <div className="text-yellow-400">
                    {affiliateData.tier >= 2 ? '✅' : '🔒'}
                  </div>
                </div>
              </div>
            </div>

            {/* Marketing Materials */}
            <div className="glass-morphism p-8 rounded-2xl border border-white/20">
              <h2 className="text-2xl font-bold text-white mb-6">Marketing Materials</h2>
              <div className="grid md:grid-cols-2 gap-6">
                <div>
                  <h3 className="text-white font-semibold mb-3">Sample Tweet</h3>
                  <div className="bg-black/40 p-4 rounded-xl border border-white/10">
                    <p className="text-sm text-gray-300 italic">
                      "🚀 Just discovered Digital Giant domains - enterprise-grade .bank, .gold, .oil TLDs with Basel III compliance built-in. Perfect for Fortune 500 companies. Use my link for exclusive access: {`${typeof window !== 'undefined' ? window.location.origin : ''}/mint?ref=${referralCode}`}"
                    </p>
                  </div>
                </div>
                <div>
                  <h3 className="text-white font-semibold mb-3">Email Template</h3>
                  <div className="bg-black/40 p-4 rounded-xl border border-white/10">
                    <p className="text-sm text-gray-300 italic">
                      "Hi [Name], I wanted to share Digital Giant's new enterprise domain registry. They offer .bank, .gold, and .oil domains with built-in compliance for financial institutions. Pricing starts at $2,500 but includes full regulatory integration..."
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* Registration Form */
          <div className="max-w-2xl mx-auto">
            <div className="glass-morphism p-8 rounded-2xl border border-white/20">
              <h2 className="text-3xl font-bold text-white mb-6 text-center">Join the Affiliate Program</h2>
              
              <form onSubmit={handleRegister} className="space-y-6">
                <div>
                  <label className="block text-white font-semibold mb-2">
                    Preferred Referral Code
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., JOHNDOE or CRYPTOKING"
                    value={preferredCode}
                    onChange={(e) => setPreferredCode(e.target.value)}
                    className="w-full bg-black/20 text-white placeholder-gray-400 border border-white/20 rounded-xl px-4 py-3 focus:border-green-400 focus:outline-none transition-colors"
                    required
                    maxLength={20}
                    minLength={3}
                  />
                  <p className="text-sm text-gray-400 mt-2">
                    3-20 characters, alphanumeric only. We'll make it unique if needed.
                  </p>
                </div>

                <div className="bg-gradient-to-r from-green-600/20 to-blue-600/20 p-6 rounded-xl border border-green-400/20">
                  <h3 className="text-white font-semibold text-lg mb-3">Commission Structure</h3>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-300">Tier 1 (Start):</span>
                      <span className="text-green-400 font-bold">5% Commission</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-300">Tier 2 ($10K+ sales):</span>
                      <span className="text-blue-400 font-bold">7% Commission</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-300">Tier 3 ($50K+ sales):</span>
                      <span className="text-purple-400 font-bold">10% Commission</span>
                    </div>
                  </div>
                </div>

                <div className="bg-black/20 p-6 rounded-xl border border-white/10">
                  <h3 className="text-white font-semibold mb-3">What You'll Earn</h3>
                  <div className="space-y-2 text-sm text-gray-300">
                    <p>• <strong className="text-white">.bank domain ($125,000)</strong> → Up to $12,500 commission</p>
                    <p>• <strong className="text-white">.usd domain ($250,000)</strong> → Up to $25,000 commission</p>
                    <p>• <strong className="text-white">.real domain ($125,000)</strong> → Up to $12,500 commission</p>
                    <p>• <strong className="text-white">.oil domain ($12,500)</strong> → Up to $1,250 commission</p>
                    <p>• <strong className="text-white">.gold domain ($2,500)</strong> → Up to $250 commission</p>
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isLoading || !preferredCode.trim()}
                  className="w-full bg-gradient-to-r from-green-500 to-blue-600 text-white py-4 rounded-xl font-semibold text-lg hover:from-green-600 hover:to-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
                >
                  {isLoading ? (
                    <div className="flex items-center justify-center space-x-2">
                      <div className="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
                      <span>Registering...</span>
                    </div>
                  ) : (
                    '🤝 Join Affiliate Program'
                  )}
                </button>
              </form>
            </div>

            {/* Benefits */}
            <div className="mt-12 grid md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-blue-600 rounded-full mx-auto mb-4 flex items-center justify-center text-2xl">
                  💰
                </div>
                <h3 className="text-white font-semibold mb-2">High Commissions</h3>
                <p className="text-sm text-gray-400">Up to 10% on enterprise domain sales worth $250,000+</p>
              </div>
              <div className="text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-600 rounded-full mx-auto mb-4 flex items-center justify-center text-2xl">
                  🚀
                </div>
                <h3 className="text-white font-semibold mb-2">Real-time Payouts</h3>
                <p className="text-sm text-gray-400">Get paid in USDC automatically after each sale</p>
              </div>
              <div className="text-center">
                <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full mx-auto mb-4 flex items-center justify-center text-2xl">
                  🎯
                </div>
                <h3 className="text-white font-semibold mb-2">Enterprise Focus</h3>
                <p className="text-sm text-gray-400">Target Fortune 500 companies, not individual consumers</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}