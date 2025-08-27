'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { useState } from 'react';

export default function Home() {
  const [searchQuery, setSearchQuery] = useState('');

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      // Redirect to domain search/resolution page
      window.location.href = `/domain/${searchQuery.trim()}`;
    }
  };

  return (
    <main className="min-h-screen">
      {/* Navigation */}
      <nav className="relative z-20 flex justify-between items-center p-6 glass-morphism">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg"></div>
          <h1 className="text-2xl font-bold text-white font-mono">Digital Giant</h1>
          <span className="text-xs bg-purple-600 text-white px-2 py-1 rounded-full">MOG</span>
        </div>
        
        <div className="hidden md:flex space-x-6 text-white">
          <Link href="/mint" className="hover:text-blue-400 transition-colors">Mint</Link>
          <Link href="/dashboard" className="hover:text-blue-400 transition-colors">Dashboard</Link>
          <Link href="/vault" className="hover:text-blue-400 transition-colors">Vault</Link>
          <Link href="/compliance" className="hover:text-blue-400 transition-colors">Compliance</Link>
        </div>

        <ConnectButton />
      </nav>

      {/* Hero Section */}
      <section className="relative px-6 py-20 text-center">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-6xl font-bold text-white mb-6">
            Your Digital
            <span className="bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent"> Giant</span>
            <br />
            Domain Empire
          </h1>
          
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            Mint, manage, and resolve sovereign domains with ERC-6551 vault binding, 
            ISO 20022 compliance, and IPFS proof notarization.
          </p>

          {/* Domain Search */}
          <form onSubmit={handleSearch} className="max-w-2xl mx-auto mb-12">
            <div className="flex glass-morphism rounded-xl p-2">
              <input
                type="text"
                placeholder="Search domains (e.g., digitalgiant.x)"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="flex-1 bg-transparent text-white placeholder-gray-400 border-none outline-none px-4 py-3 text-lg"
              />
              <button
                type="submit"
                className="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-6 py-3 rounded-lg font-semibold hover:from-blue-600 hover:to-purple-700 transition-all duration-200"
              >
                Search
              </button>
            </div>
          </form>

          {/* Action Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
            <Link 
              href="/mint"
              className="bg-gradient-to-r from-blue-500 to-purple-600 text-white px-8 py-4 rounded-xl font-semibold text-lg hover:from-blue-600 hover:to-purple-700 transition-all duration-200 transform hover:scale-105"
            >
              🚀 Mint Domain
            </Link>
            <Link 
              href="/dashboard"
              className="glass-morphism text-white px-8 py-4 rounded-xl font-semibold text-lg hover:bg-white/20 transition-all duration-200 border border-white/20"
            >
              📊 Dashboard
            </Link>
            <Link 
              href="/vault"
              className="glass-morphism text-white px-8 py-4 rounded-xl font-semibold text-lg hover:bg-white/20 transition-all duration-200 border border-white/20"
            >
              🏦 Vaults
            </Link>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="px-6 py-20">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-4xl font-bold text-white text-center mb-16">
            Powered by <span className="text-blue-400">MOG Stack</span>
          </h2>
          
          <div className="grid md:grid-cols-3 gap-8">
            {/* Feature 1 */}
            <div className="domain-card glass-morphism p-8 rounded-2xl border border-white/20">
              <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl mb-6 flex items-center justify-center text-2xl">
                🏛️
              </div>
              <h3 className="text-xl font-bold text-white mb-4">ERC-6551 Vaults</h3>
              <p className="text-gray-300">
                Each domain becomes a programmable account with vault binding for advanced DeFi operations.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="domain-card glass-morphism p-8 rounded-2xl border border-white/20">
              <div className="w-16 h-16 bg-gradient-to-r from-purple-500 to-pink-600 rounded-xl mb-6 flex items-center justify-center text-2xl">
                🛡️
              </div>
              <h3 className="text-xl font-bold text-white mb-4">ISO 20022 Compliance</h3>
              <p className="text-gray-300">
                Corporate documentation proofs with banking-grade compliance standards and verification.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="domain-card glass-morphism p-8 rounded-2xl border border-white/20">
              <div className="w-16 h-16 bg-gradient-to-r from-green-500 to-blue-600 rounded-xl mb-6 flex items-center justify-center text-2xl">
                📡
              </div>
              <h3 className="text-xl font-bold text-white mb-4">IPFS Notarization</h3>
              <p className="text-gray-300">
                Decentralized proof storage with Pinata integration for immutable document verification.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="px-6 py-20">
        <div className="max-w-4xl mx-auto glass-morphism p-8 rounded-2xl border border-white/20">
          <div className="grid md:grid-cols-4 gap-8 text-center">
            <div>
              <div className="text-3xl font-bold text-white mb-2">0</div>
              <div className="text-gray-300">Domains Minted</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-white mb-2">0</div>
              <div className="text-gray-300">Active Vaults</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-white mb-2">0</div>
              <div className="text-gray-300">Compliance Proofs</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-white mb-2">$0</div>
              <div className="text-gray-300">Total Value Locked</div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="px-6 py-12 text-center text-gray-400">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center justify-center space-x-2 mb-4">
            <div className="w-6 h-6 bg-gradient-to-r from-blue-500 to-purple-600 rounded"></div>
            <span className="font-mono font-bold">Digital Giant x MOG</span>
          </div>
          <p className="text-sm">
            Sovereign domains with programmable accounts • Built on Polygon • Powered by Unstoppable Domains stack
          </p>
        </div>
      </footer>
    </main>
  );
}