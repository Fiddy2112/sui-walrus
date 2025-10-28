// SPDX-License-Identifier: MIT
module profiles::profiles {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::event::{Self, Event, EventHandle};
    use sui::vector;
    use sui::bcs;
    use sui::signer;
    use sui::address;
    use sui::string;
    use sui::timestamp;

    /// Developer profile object stored under owner's account
    struct DeveloperProfile has key {
        id: UID,
        owner: address,
        handle: string::String,
        display_name: string::String,
        bio_ptr: Option<string::String>,
        social_links: vector<vector<u8>>,
        avatar_ptr: Option<string::String>,
        banner_ptr: Option<string::String>,
        verified_by: Option<address>,
        created_at: u64,
        updated_at: u64
    }


    struct Project has key {
        id: UID,
        owner: address,
        title: string::String,
        description_ptr: Option<string::String>,
        demo_link: Option<string::String>,
        thumbnails: vector<string::String>,
        created_at: u64
    }


    struct Certificate has key {
        id: UID,
        owner: address,
        title: string::String,
        scan_ptr: Option<string::String>,
        issuer: Option<string::String>,
        issued_at: u64
    }


    struct VerifierCap has key {
        id: UID,
        admin: address
    }


    struct ProfileEvent has copy, drop, store {
        owner: address,
        handle: string::String,
        action: string::String, // "created" | "updated" | "verified"
    }

    struct ProfileEvents has key {
        id: UID,
        handle: EventHandle<ProfileEvent>,
    }

    // ============= Helpers =============
    fun now_seconds(): u64 {
        // Sui provides timestamp::now_seconds() in many versions
        timestamp::now_seconds()
    }

    // ============= Entry functions =============

    /// Initialize VerifierCap for admin (call once by deployer/admin)
    public entry fun init_admin(admin: &signer, tx: &mut TxContext) {
        let admin_addr = signer::address_of(admin);
        let cap = VerifierCap { id: UID::new(tx), admin: admin_addr };
        move_to(admin, cap);
        // also create event handle container for indexing if desired
        let ev = ProfileEvents { id: UID::new(tx), handle: Event::new_handle<ProfileEvent>(tx) };
        move_to(admin, ev);
    }

    /// Create profile. Owner will own the DeveloperProfile object.
    public entry fun create_profile(owner: &signer, handle: string::String, display_name: string::String, avatar_ptr: Option<string::String>, tx: &mut TxContext) {
        let owner_addr = signer::address_of(owner);
        let now = now_seconds();
        let profile = DeveloperProfile {
            id: UID::new(tx),
            owner: owner_addr,
            handle: handle,
            display_name: display_name,
            bio_ptr: Option::none<string::String>(),
            social_links: vector::empty<vector<u8>>(),
            avatar_ptr,
            banner_ptr: Option::none<string::String>(),
            verified_by: Option::none<address>(),
            created_at: now,
            updated_at: now
        };
        move_to(owner, profile);

        // emit event using owner's event handle if you want; for simplicity, emit to deployer/admin event handle
        // If you want global event stream, consider creating a Registry object that holds an EventHandle and is owned by deployer.
    }

    /// Update profile fields (owner only)
    public entry fun update_profile(owner: &signer, new_display: Option<string::String>, new_bio_ptr: Option<string::String>, new_avatar_ptr: Option<string::String>) {
        let owner_addr = signer::address_of(owner);
        // borrow global mutable profile owned by owner
        let profile_ref = borrow_global_mut<DeveloperProfile>(owner_addr);
        if (Option::is_some(&new_display)) {
            profile_ref.display_name = Option::extract(new_display);
        };
        if (Option::is_some(&new_bio_ptr)) {
            profile_ref.bio_ptr = Option::some(Option::extract(new_bio_ptr));
        };
        if (Option::is_some(&new_avatar_ptr)) {
            profile_ref.avatar_ptr = Option::some(Option::extract(new_avatar_ptr));
        };
        profile_ref.updated_at = now_seconds();
    }

    public entry fun add_project(owner: &signer, title: string::String, desc_ptr: Option<string::String>, demo_link: Option<string::String>, thumbs: vector<string::String>, tx: &mut TxContext) {
        let owner_addr = signer::address_of(owner);
        let proj = Project {
            id: UID::new(tx),
            owner: owner_addr,
            title,
            description_ptr: desc_ptr,
            demo_link,
            thumbnails: thumbs,
            created_at: now_seconds()
        };
        move_to(owner, proj);
        // you can optionally add project id to profile by moving profile ownership pattern or via off-chain indexer.
    }

    public entry fun add_certificate(owner: &signer, title: string::String, scan_ptr: Option<string::String>, issuer: Option<string::String>, tx: &mut TxContext) {
        let owner_addr = signer::address_of(owner);
        let cert = Certificate {
            id: UID::new(tx),
            owner: owner_addr,
            title,
            scan_ptr,
            issuer,
            issued_at: now_seconds()
        };
        move_to(owner, cert);
    }

    /// Admin-only verify profile (admin must hold VerifierCap resource)
    public entry fun verify_profile(admin: &signer, profile_owner: address) {
        let admin_addr = signer::address_of(admin);
        // Check VerifierCap exists for signer
        assert!(exists<VerifierCap>(admin_addr), 100);
        let cap = borrow_global<VerifierCap>(admin_addr);
        assert!(cap.admin == admin_addr, 101);

        let profile_ref = borrow_global_mut<DeveloperProfile>(profile_owner);
        profile_ref.verified_by = Option::some(admin_addr);
        profile_ref.updated_at = now_seconds();
    }

    /// Revoke verification
    public entry fun revoke_verify(admin: &signer, profile_owner: address) {
        let admin_addr = signer::address_of(admin);
        assert!(exists<VerifierCap>(admin_addr), 110);
        let _cap = borrow_global<VerifierCap>(admin_addr);
        let profile_ref = borrow_global_mut<DeveloperProfile>(profile_owner);
        profile_ref.verified_by = Option::none<address>();
        profile_ref.updated_at = now_seconds();
    }
}
