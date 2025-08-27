import { createConfig, http } from 'wagmi';
import { polygon } from 'wagmi/chains';
import { getDefaultConfig } from '@rainbow-me/rainbowkit';

export const config = getDefaultConfig({
  appName: 'Digital Giant Portal',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || 'digital-giant-portal',
  chains: [polygon],
  transports: {
    [polygon.id]: http(process.env.NEXT_PUBLIC_RPC_URL || 'https://polygon-rpc.com'),
  },
  ssr: true,
});

export const SUPPORTED_CHAINS = [polygon] as const;
export type SupportedChainId = typeof SUPPORTED_CHAINS[number]['id'];