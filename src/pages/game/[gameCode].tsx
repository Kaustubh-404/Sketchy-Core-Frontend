import { useEffect } from 'react';
import { useRouter } from 'next/router';
import { useAccount } from 'wagmi';
import { GameRoom } from '@/components/GameRoom';
import { useGameStore } from '@/store/gameStore';
import { io } from 'socket.io-client';
import { toast } from 'react-hot-toast';

export default function GamePage() {
  const router = useRouter();
  const { gameCode } = router.query;
  const { address } = useAccount();
  const { reset } = useGameStore();

  useEffect(() => {
    if (!gameCode || !address) return;

    const socket = io(process.env.NEXT_PUBLIC_SOCKET_URL!, {
      query: { gameCode, address },
    });

    // socket.on('gameState', (state) => {
    //   // Update game state
    // });

    socket.on('gameEnd', async (data) => {

      const resultCardElement = document.getElementById('game-result-root');
  if (!resultCardElement) {
    if (data.winner === address) {
      toast.success('🎉 Congratulations! You won!');
    } else {
      toast.error('Game Over! Better luck next time!');
    }
    reset();
    router.push('/');
  }
    });

    return () => {
      socket.disconnect();
    };
  }, [gameCode, address, reset, router]);

  if (!gameCode || !address) return null;

  return <GameRoom />;
}


