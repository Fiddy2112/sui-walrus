// SPDX-License-Identifier: MIT
module profiles::profiles {
    use std::option::{Self, Option};
    use sui::address;
    use sui::bcs;
    use sui::event::{Self, EventHandle};
    use sui::object::{Self, UID, ID};
    use sui::signer;
    use sui::string;
    use sui::table::{Self, Table};
    use sui::timestamp;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vector;

    /* ========= Core objects ========= */

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
        updated_at: u64,
    }

    struct Project has key {
        id: UID,
        owner: address,
        title: string::String,
        description_ptr: Option<string::String>,
        demo_link: Option<string::String>,
        thumbnails: vector<string::String>,
        created_at: u64,
    }

    struct Certificate has key {
        id: UID,
        owner: address,
        title: string::String,
        scan_ptr: Option<string::String>,
        issuer: Option<string::String>,
        issued_at: u64,
    }

    struct VerifierCap has key { id: UID, admin: address }

    struct ProfileEvent has copy, drop, store {
        owner: address,
        handle: string::String,
        action: string::String, // "created" | "updated" | "verified"
    }

    // Shared singleton để phát event
    struct Events has key {
        id: UID,
        handle: EventHandle<ProfileEvent>,
    }

    // Shared registry: address -> profile object id
    struct Registry has key {
        id: UID,
        map: Table<address, ID>,
    }

    /* ========= Helpers ========= */
    fun now_seconds(): u64 { timestamp::now_seconds() }

    fun emit(events: &mut Events, owner: address, handle: &string::String, action: vector<u8>) {
        event::emit(&mut events.handle, ProfileEvent {
            owner,
            handle: handle.clone(),
            action: string::utf8(action),
        });
    }

    /* ========= Init (call once by deployer) ========= */
    public entry fun init_admin(admin: &signer, tx: &mut TxContext) {
        let admin_addr = signer::address_of(admin);

        // cap (owned by admin)
        let cap = VerifierCap { id: object::new(tx), admin: admin_addr };
        move_to(admin, cap);

        // shared events
        let ev = Events { id: object::new(tx), handle: event::new_handle<ProfileEvent>(tx) };
        transfer::share_object(ev);

        // shared registry
        let reg = Registry { id: object::new(tx), map: table::new<address, ID>(tx) };
        transfer::share_object(reg);
    }

    /* ========= Entry functions ========= */

    /// Create profile: cần truyền vào &mut Registry và &mut Events (shared)
    public entry fun create_profile(
        owner: &signer,
        registry: &mut Registry,
        events: &mut Events,
        handle: string::String,
        display_name: string::String,
        avatar_ptr: Option<string::String>,
        tx: &mut TxContext
    ) {
        let owner_addr = signer::address_of(owner);
        assert!(!exists<DeveloperProfile>(owner_addr), 201);

        let now = now_seconds();
        let profile = DeveloperProfile {
            id: object::new(tx),
            owner: owner_addr,
            handle: handle.clone(),
            display_name,
            bio_ptr: Option::none<string::String>(),
            social_links: vector::empty<vector<u8>>(),
            avatar_ptr,
            banner_ptr: Option::none<string::String>(),
            verified_by: Option::none<address>(),
            created_at: now,
            updated_at: now,
        };
        let pid = object::id(&profile.id);

        table::add(&mut registry.map, owner_addr, pid);
        move_to(owner, profile);

        emit(events, owner_addr, &handle, b"created");
    }

    /// Update profile (owner)
    public entry fun update_profile(
        owner: &signer,
        events: &mut Events,
        new_display: Option<string::String>,
        new_bio_ptr: Option<string::String>,
        new_avatar_ptr: Option<string::String>
    ) {
        let owner_addr = signer::address_of(owner);
        assert!(exists<DeveloperProfile>(owner_addr), 200);
        let p = borrow_global_mut<DeveloperProfile>(owner_addr);

        if (Option::is_some(&new_display)) {
            p.display_name = Option::extract(new_display);
        };
        if (Option::is_some(&new_bio_ptr)) {
            p.bio_ptr = Option::some(Option::extract(new_bio_ptr));
        };
        if (Option::is_some(&new_avatar_ptr)) {
            p.avatar_ptr = Option::some(Option::extract(new_avatar_ptr));
        };
        p.updated_at = now_seconds();

        emit(events, owner_addr, &p.handle, b"updated");
    }

    public entry fun add_project(
        owner: &signer,
        title: string::String,
        desc_ptr: Option<string::String>,
        demo_link: Option<string::String>,
        thumbs: vector<string::String>,
        tx: &mut TxContext
    ) {
        let owner_addr = signer::address_of(owner);
        let proj = Project {
            id: object::new(tx),
            owner: owner_addr,
            title,
            description_ptr: desc_ptr,
            demo_link,
            thumbnails: thumbs,
            created_at: now_seconds(),
        };
        move_to(owner, proj);
    }

    public entry fun add_certificate(
        owner: &signer,
        title: string::String,
        scan_ptr: Option<string::String>,
        issuer: Option<string::String>,
        tx: &mut TxContext
    ) {
        let owner_addr = signer::address_of(owner);
        let cert = Certificate {
            id: object::new(tx),
            owner: owner_addr,
            title,
            scan_ptr,
            issuer,
            issued_at: now_seconds(),
        };
        move_to(owner, cert);
    }

    public entry fun delete_profile(
        owner: &signer,
        registry: &mut Registry
    ) {
        let addr = signer::address_of(owner);
        let profile = move_from<DeveloperProfile>(addr);
        table::remove(&mut registry.map, addr);
        object::delete(profile.id);
    }

    /// Verify / revoke (admin needs VerifierCap)
    public entry fun verify_profile(
        admin: &signer,
        events: &mut Events,
        profile_owner: address
    ) {
        let admin_addr = signer::address_of(admin);
        assert!(exists<VerifierCap>(admin_addr), 100);
        let p = borrow_global_mut<DeveloperProfile>(profile_owner);
        p.verified_by = Option::some(admin_addr);
        p.updated_at = now_seconds();
        emit(events, profile_owner, &p.handle, b"verified");
    }

    public entry fun revoke_verify(admin: &signer, profile_owner: address) {
        let admin_addr = signer::address_of(admin);
        assert!(exists<VerifierCap>(admin_addr), 110);
        let p = borrow_global_mut<DeveloperProfile>(profile_owner);
        p.verified_by = Option::none<address>();
        p.updated_at = now_seconds();
    }
}
