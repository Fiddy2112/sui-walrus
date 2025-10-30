import { Transaction } from '@mysten/sui/transactions';
import { PKG_ID } from './sui';
import { normalizeSuiAddress } from '@mysten/sui/utils';
import type { PureTypeName } from '@mysten/sui/bcs';

export const MOD = 'profiles';

const STR = '0x1::string::String';

const tx = new Transaction();

export const TARGETS = {
  create:  `${PKG_ID}::${MOD}::create_profile`,
  update:  `${PKG_ID}::${MOD}::update_profile`,
  del:     `${PKG_ID}::${MOD}::delete_profile`,
  verify:  `${PKG_ID}::${MOD}::verify_profile`,
  addProj: `${PKG_ID}::${MOD}::add_project`,
  addCert: `${PKG_ID}::${MOD}::add_certificate`,
} as const;

function sharedRef(id:string, initialSharedVersion:string | number){
    if(initialSharedVersion !== undefined){
        return tx.sharedObjectRef({
            objectId: id,
            initialSharedVersion: String(initialSharedVersion),
            mutable:true
        })
    }
    return id;
}

// profile
export function buildCreateProfileTx(
    args:{
        registryId:string;
        eventsId:string;
        handle:string;
        displayName:string;
        avatarProfile:string | null;
        registryVersion?: string | number;
        eventsVersion?: string | number;
    }){
    tx.moveCall({
        target: TARGETS.create,
        arguments:[
            tx.object(sharedRef(args.registryId, args.registryVersion as string)),
            tx.object(sharedRef(args.eventsId, args.eventsVersion as string)),
            tx.pure.string(args.handle),
            tx.pure.string(args.displayName),
            tx.pure.option(STR as PureTypeName, args.avatarProfile ?? null),
        ],
    });
    return tx;
}

export function buildUpdateProfileTx(args:{
    eventsId: string;
    display?: string | null;
    bioProfile?: string | null;
    avatarProfile?: string | null;
    eventsVersion?: string | number;
}){
    tx.moveCall({
        target: TARGETS.update,
        arguments: [
            tx.object(sharedRef(args.eventsId, args.eventsVersion as string)),
            tx.pure.option(STR as PureTypeName, args.display ?? null),
            tx.pure.option(STR as PureTypeName, args.bioProfile ?? null),
            tx.pure.option(STR as PureTypeName, args.avatarProfile ?? null),
        ],
    });
    return tx;
}

export function buildVerifyTx(args:{
    eventsId: string;
    profileOwner: string;
    eventsVersion?: string | number;
}){
    tx.moveCall({
        target: TARGETS.verify,
        arguments:[
            tx.object(sharedRef(args.eventsId, args.eventsVersion as string)),
            tx.pure.address(normalizeSuiAddress(args.profileOwner)),
        ],
    });
    return tx;
}

export function buildAddProjectTx(p:{
    title:string;
    descProfile?: string | null;
    demo?: string | null;
    thumbs: string[];
}){
    tx.moveCall({
        target: TARGETS.addProj,
    arguments: [
      tx.pure.string(p.title),
      tx.pure.option(STR as PureTypeName, p.descProfile ?? null),
      tx.pure.option(STR as PureTypeName, p.demo ?? null),
      tx.pure.vector(STR as PureTypeName, p.thumbs),
    ],
    });
    return tx;
}

export function buildAddCertificateTx(p: {
  title: string;
  scanPtr?: string | null;
  issuer?: string | null;
}) {
  const tx = new Transaction();
  tx.moveCall({
    target: TARGETS.addCert,
    arguments: [
      tx.pure.string(p.title),
      tx.pure.option(STR as PureTypeName, p.scanPtr ?? null),
      tx.pure.option(STR as PureTypeName, p.issuer ?? null),
    ],
  });
  return tx;
}