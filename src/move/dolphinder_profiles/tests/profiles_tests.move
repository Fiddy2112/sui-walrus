module profiles::profiles_test {
    use std::option::{Self, Option};
    use std::string;
    use sui::object::{Self, UID, ID};
    use sui::table;
    use sui::tx_context;
    use sui::event;
    use sui::test_scenario as TS;

    use profiles::profiles::{
        Self, DeveloperProfile, Registry, Events, VerifierCap,
        create_profile, update_profile, delete_profile,
        verify_profile, revoke_verify
    };

    // Create Registry/Events "local" with unit test (no share)
    fun new_registry_and_events(ctx: &mut tx_context::TxContext): (Registry, Events) {
        let reg = Registry { id: object::new(ctx), map: table::new<address, ID>(ctx) };
        let ev  = Events   { id: object::new(ctx), handle: event::new_handle<profiles::profiles::ProfileEvent>(ctx) };
        (reg, ev)
    }

    #[test]
    fun test_create_update_delete_profile() {
        let mut s = TS::new();
        let admin = @0xA;
        let alice = @0x1;

        // Create local Registry/Events + Create profile
        TS::next_tx(&mut s, alice);
        let ctx1 = TS::ctx(&mut s);
        let (mut reg, mut ev) = new_registry_and_events(ctx1);

        create_profile(
            &TS::account(alice),
            &mut reg,
            &mut ev,
            string::utf8(b"alice"),
            string::utf8(b"Alice Doe"),
            Option::none<string::String>(),
            ctx1
        );
        TS::finish_tx(&mut s);

        // Assert: profile exists & Registry has entry
        assert!(exists<DeveloperProfile>(alice), 1);
        assert!(table::contains(&reg.map, alice), 2);

        // TX2: update display & avatar_ptr
        TS::next_tx(&mut s, alice);
        let ctx2 = TS::ctx(&mut s);
        update_profile(
            &TS::account(alice),
            &mut ev,
            Option::some(string::utf8(b"Alice Updated")),
            Option::none<string::String>(),
            Option::some(string::utf8(b"wal://avatar123"))
        );
        TS::finish_tx(&mut s);

        // Check updated value
        {
            let p = borrow_global<DeveloperProfile>(alice);
            assert!(string::bytes_equal(&p.display_name, b"Alice Updated"), 3);
            assert!(Option::is_some(&p.avatar_ptr), 4);
        };

        // Delete profile and registry
        TS::next_tx(&mut s, alice);
        let _ctx3 = TS::ctx(&mut s);
        delete_profile(&TS::account(alice), &mut reg);
        TS::finish_tx(&mut s);

        assert!(!exists<DeveloperProfile>(alice), 5);
        assert!(!table::contains(&reg.map, alice), 6)

        TS::end(&mut s);
        let _keep = (reg, ev, admin); // tránh "unused"
    }

    // Verify need VerifierCap – Check abort when there is NO cap
    #[test, expected_failure(abort_code = 100)]
    fun test_verify_requires_cap() {
        let mut s = TS::new();
        let admin = @0xA;
        let bob   = @0x2;

        // Create Registry/Events + profile with Bob
        TS::next_tx(&mut s, bob);
        let ctx1 = TS::ctx(&mut s);
        let (mut reg, mut ev) = new_registry_and_events(ctx1);
        create_profile(&TS::account(bob), &mut reg, &mut ev,
            string::utf8(b"bob"), string::utf8(b"Bob"),
            Option::none<string::String>(), ctx1);
        TS::finish_tx(&mut s);

        // Admin tried to verify but did NOT have VerifierCap -> abort 100
        TS::next_tx(&mut s, admin);
        let _ctx2 = TS::ctx(&mut s);
        verify_profile(&TS::account(admin), &mut ev, bob);
        TS::finish_tx(&mut s);
    }

    // Verify successful with VerifierCap
    #[test]
    fun test_verify_success() {
        let mut s = TS::new();
        let admin = @0xA;
        let bob   = @0x2;

        // Create Registry/Events + profile for Bob
        TS::next_tx(&mut s, bob);
        let ctx1 = TS::ctx(&mut s);
        let (mut reg, mut ev) = new_registry_and_events(ctx1);
        create_profile(&TS::account(bob), &mut reg, &mut ev,
            string::utf8(b"bob"), string::utf8(b"Bob"),
            Option::none<string::String>(), ctx1);
        TS::finish_tx(&mut s);

        // Admin VerifierCap (move on admin)
        TS::next_tx(&mut s, admin);
        let ctx2 = TS::ctx(&mut s);
        let cap = VerifierCap { id: object::new(ctx2), admin };
        move_to(&TS::account(admin), cap);

        // Verify OK
        verify_profile(&TS::account(admin), &mut ev, bob);
        TS::finish_tx(&mut s);

        // Check state
        {
            let p = borrow_global<DeveloperProfile>(bob);
            assert!(Option::is_some(&p.verified_by), 10);
        };

        // Revoke
        TS::next_tx(&mut s, admin);
        let _ctx3 = TS::ctx(&mut s);
        revoke_verify(&TS::account(admin), bob);
        TS::finish_tx(&mut s);

        {
            let p2 = borrow_global<DeveloperProfile>(bob);
            assert!(!Option::is_some(&p2.verified_by), 11);
        };

        TS::end(&mut s);
        let _keep = (reg, ev);
    }
}
