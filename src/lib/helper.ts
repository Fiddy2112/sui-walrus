import { normalizeSuiAddress } from '@mysten/sui/utils';
import { client } from './sui';
import type { SuiClient } from '@mysten/sui/client';

export function normalizeAddr(add:string):string {
   return normalizeSuiAddress(add) 
}

export async function getObject(id:string, client: SuiClient){
    return client.getObject({
        id,
        options: { showContent:true, showOwner:true}
    })
}

export async function getOwnedByType(owner:string, structType: string){
    return client.getOwnedObjects({
      owner,
      filter:{StructType: structType},
      options:{showContent:true},
    });
}

export async function getDynamicFields(parentId:string){
  return client.getDynamicFields({parentId});
}