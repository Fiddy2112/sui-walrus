import React,{useState, useEffect} from "react";
import { getWallets } from '@mysten/wallet-standard';

const WalletConnect = () => {
const [wallet, setWallet] = useState(null);

useEffect(() => {
  const wallets = getWallets();
  const suiWallet = wallets.get().find((w) => w.name.includes('Sui Wallet'));
  if (suiWallet) setWallet(suiWallet);
}, []);

  return (
    {wallet ? (
  <button onClick={() => wallet.connect()}>Connect Sui Wallet</button>
) : (
  <p>No wallet detected</p>
)}
  )
};

export default WalletConnect;
