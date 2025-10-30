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
  <h2>hello</h2>
)
};

export default WalletConnect;
