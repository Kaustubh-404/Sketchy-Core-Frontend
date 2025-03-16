import { useAccount } from 'wagmi';
import { useRouter } from 'next/router';
import { ConnectButton } from '@rainbow-me/rainbowkit';

interface ConnectionGuardProps {
  children: React.ReactNode;
}

export const ConnectionGuard = ({ children }: ConnectionGuardProps) => {
  const { address } = useAccount();
  const router = useRouter();
  const publicPaths = ['/', '/connect'];

  if (!address && !publicPaths.includes(router.pathname)) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="p-8 bg-white rounded-lg shadow-lg text-center">
          <h2 className="text-2xl font-bold mb-4">Wallet Connection Required</h2>
          <p className="text-gray-600 mb-4">Please connect your wallet to continue</p>
          <ConnectButton />
        </div>
      </div>
    );
  }

  return <>{children}</>;
};