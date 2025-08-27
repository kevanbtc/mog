'use client';

import { useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { useAccount } from 'wagmi';

export default function MintPage() {
  const { address, isConnected } = useAccount();
  const [domainName, setDomainName] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [uploadedFiles, setUploadedFiles] = useState<File[]>([]);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setUploadedFiles(Array.from(e.target.files));
    }
  };

  const handleMint = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isConnected || !domainName.trim()) return;

    setIsLoading(true);
    try {
      // TODO: Implement minting logic
      console.log('Minting domain:', domainName);
      console.log('Files to upload:', uploadedFiles);
      
      // Placeholder for actual implementation
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      alert('Domain minted successfully! (Placeholder)');
    } catch (error) {
      console.error('Minting failed:', error);
      alert('Minting failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="min-h-screen">
      {/* Navigation */}
      <nav className="relative z-20 flex justify-between items-center p-6 glass-morphism">
        <Link href="/" className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg"></div>
          <h1 className="text-2xl font-bold text-white font-mono">Digital Giant</h1>
          <span className="text-xs bg-purple-600 text-white px-2 py-1 rounded-full">MOG</span>
        </Link>
        
        <div className="hidden md:flex space-x-6 text-white">
          <Link href="/" className="hover:text-blue-400 transition-colors">Home</Link>
          <Link href="/dashboard" className="hover:text-blue-400 transition-colors">Dashboard</Link>
          <Link href="/vault" className="hover:text-blue-400 transition-colors">Vault</Link>
          <Link href="/compliance" className="hover:text-blue-400 transition-colors">Compliance</Link>
        </div>

        <ConnectButton />
      </nav>

      {/* Main Content */}
      <div className="max-w-4xl mx-auto px-6 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-white mb-4">
            Mint Your <span className="bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">Digital Giant</span> Domain
          </h1>
          <p className="text-xl text-gray-300 max-w-2xl mx-auto">
            Create a sovereign domain with ERC-6551 vault binding and MOG compliance integration.
          </p>
        </div>

        {!isConnected ? (
          /* Connect Wallet Prompt */
          <div className="text-center">
            <div className="glass-morphism p-12 rounded-2xl border border-white/20 max-w-md mx-auto">
              <div className="text-6xl mb-4">🔗</div>
              <h2 className="text-2xl font-bold text-white mb-4">Connect Wallet</h2>
              <p className="text-gray-300 mb-6">Connect your wallet to mint Digital Giant domains</p>
              <ConnectButton />
            </div>
          </div>
        ) : (
          /* Minting Form */
          <div className="glass-morphism p-8 rounded-2xl border border-white/20">
            <form onSubmit={handleMint} className="space-y-8">
              {/* Domain Name Input */}
              <div>
                <label className="block text-white font-semibold mb-2">
                  Domain Name
                </label>
                <div className="relative">
                  <input
                    type="text"
                    placeholder="Enter domain name"
                    value={domainName}
                    onChange={(e) => setDomainName(e.target.value)}
                    className="w-full bg-black/20 text-white placeholder-gray-400 border border-white/20 rounded-xl px-4 py-3 text-lg focus:border-blue-400 focus:outline-none transition-colors"
                    required
                  />
                  <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400">
                    .x
                  </span>
                </div>
                <p className="text-sm text-gray-400 mt-2">
                  Your domain will be: <span className="text-blue-400 font-mono">{domainName || 'yourdomain'}.x</span>
                </p>
              </div>

              {/* File Upload for Compliance Documents */}
              <div>
                <label className="block text-white font-semibold mb-2">
                  Compliance Documents (Optional)
                </label>
                <div className="border-2 border-dashed border-white/20 rounded-xl p-8 text-center hover:border-white/40 transition-colors">
                  <input
                    type="file"
                    multiple
                    accept=".pdf,.doc,.docx,.png,.jpg,.jpeg"
                    onChange={handleFileUpload}
                    className="hidden"
                    id="file-upload"
                  />
                  <label htmlFor="file-upload" className="cursor-pointer">
                    <div className="text-4xl mb-4">📄</div>
                    <p className="text-white mb-2">Click to upload documents</p>
                    <p className="text-sm text-gray-400">
                      EIN confirmation, Articles of Organization, Operating Agreement
                    </p>
                  </label>
                </div>
                
                {uploadedFiles.length > 0 && (
                  <div className="mt-4">
                    <p className="text-white font-semibold mb-2">Uploaded Files:</p>
                    <div className="space-y-2">
                      {uploadedFiles.map((file, index) => (
                        <div key={index} className="flex items-center space-x-2 text-sm">
                          <span className="text-green-400">✓</span>
                          <span className="text-gray-300">{file.name}</span>
                          <span className="text-gray-500">({(file.size / 1024 / 1024).toFixed(2)} MB)</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Domain Features */}
              <div className="grid md:grid-cols-3 gap-4">
                <div className="bg-black/20 p-4 rounded-xl border border-white/10">
                  <div className="text-2xl mb-2">🏦</div>
                  <h3 className="text-white font-semibold mb-1">ERC-6551 Vault</h3>
                  <p className="text-sm text-gray-400">Programmable account binding</p>
                </div>
                <div className="bg-black/20 p-4 rounded-xl border border-white/10">
                  <div className="text-2xl mb-2">🛡️</div>
                  <h3 className="text-white font-semibold mb-1">ISO 20022</h3>
                  <p className="text-sm text-gray-400">Compliance ready</p>
                </div>
                <div className="bg-black/20 p-4 rounded-xl border border-white/10">
                  <div className="text-2xl mb-2">📡</div>
                  <h3 className="text-white font-semibold mb-1">IPFS Proof</h3>
                  <p className="text-sm text-gray-400">Decentralized storage</p>
                </div>
              </div>

              {/* Pricing Info */}
              <div className="bg-gradient-to-r from-blue-600/20 to-purple-600/20 p-6 rounded-xl border border-blue-400/20">
                <div className="flex justify-between items-center">
                  <div>
                    <h3 className="text-white font-semibold text-lg">Minting Cost</h3>
                    <p className="text-gray-300">Gas fees + domain registration</p>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold text-white">~0.001 MATIC</div>
                    <div className="text-sm text-gray-400">+ gas fees</div>
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={isLoading || !domainName.trim()}
                className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-4 rounded-xl font-semibold text-lg hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-[1.02]"
              >
                {isLoading ? (
                  <div className="flex items-center justify-center space-x-2">
                    <div className="w-5 h-5 border-2 border-white/20 border-t-white rounded-full animate-spin"></div>
                    <span>Minting Domain...</span>
                  </div>
                ) : (
                  `🚀 Mint ${domainName || 'Domain'}.x`
                )}
              </button>
            </form>
          </div>
        )}

        {/* How It Works */}
        <div className="mt-16">
          <h2 className="text-3xl font-bold text-white text-center mb-8">How It Works</h2>
          <div className="grid md:grid-cols-4 gap-6">
            <div className="text-center">
              <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full mx-auto mb-4 flex items-center justify-center text-white font-bold">
                1
              </div>
              <h3 className="text-white font-semibold mb-2">Choose Domain</h3>
              <p className="text-sm text-gray-400">Select your unique .x domain name</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-600 rounded-full mx-auto mb-4 flex items-center justify-center text-white font-bold">
                2
              </div>
              <h3 className="text-white font-semibold mb-2">Upload Docs</h3>
              <p className="text-sm text-gray-400">Add compliance documents to IPFS</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-gradient-to-r from-pink-500 to-red-600 rounded-full mx-auto mb-4 flex items-center justify-center text-white font-bold">
                3
              </div>
              <h3 className="text-white font-semibold mb-2">Mint NFT</h3>
              <p className="text-sm text-gray-400">Create domain NFT with vault binding</p>
            </div>
            <div className="text-center">
              <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-blue-600 rounded-full mx-auto mb-4 flex items-center justify-center text-white font-bold">
                4
              </div>
              <h3 className="text-white font-semibold mb-2">Go Live</h3>
              <p className="text-sm text-gray-400">Domain resolves to your wallet</p>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}