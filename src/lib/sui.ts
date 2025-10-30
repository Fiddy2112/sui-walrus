import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';



export const SUI_NETWORK = (import.meta.env.PUBLIC_SUI_NETWORK as string) || 'testnet';
export const PKG_ID = (import.meta.env.PUBLIC_PKG_ID as string) || '';
if (!PKG_ID) throw new Error('❌ Missing PUBLIC_PKG_ID in environment');

export const client = new SuiClient({
  url: getFullnodeUrl('testnet'),
});




