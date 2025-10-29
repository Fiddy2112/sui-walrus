import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';

export const client = new SuiClient({ url: getFullnodeUrl('testnet') });

export async function createProfile(walletAddress, packageId, handle, display, avatarCid) {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${packageId}::profiles::create_profile`,
    arguments: [
      tx.pure.address(walletAddress),
      tx.pure.string(handle),
      tx.pure.string(display),
      tx.pure.optionSome(tx.pure.string(avatarCid)),
    ],
  });
  return tx;
}
