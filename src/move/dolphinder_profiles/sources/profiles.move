module profiles::profiles {
    use std::string;
    use std::option;
    use sui::object::UID;
    use sui::tx_context;
    use sui::transfer;
    use sui::object;

    /// Profile Developer
    public struct DeveloperProfile has key {
        id: UID,
        owner: address,
        display_name: string::String,
        bio: option::Option<string::String>,
        avatar: option::Option<string::String>,
        banner: option::Option<string::String>,
        verified_by: option::Option<address>,
    }

    public fun create_profile(
        ctx: &mut tx_context::TxContext,
        display_name: string::String,
        bio: option::Option<string::String>,
        avatar: option::Option<string::String>,
    ) {
        let sender = tx_context::sender(ctx);
        let profile = DeveloperProfile {
            id: object::new(ctx),
            owner: sender,
            display_name,
            bio,
            avatar,
            banner: option::none<string::String>(),
            verified_by: option::none<address>(),
        };
        transfer::transfer(profile, sender);
    }

    public fun update_profile(
        profile: &mut DeveloperProfile,
        mut new_display: option::Option<string::String>,
        mut new_bio: option::Option<string::String>,
        mut new_avatar: option::Option<string::String>,
    ) {
        if (option::is_some(&new_display)) {
            profile.display_name = option::extract(&mut new_display);
        };
        if (option::is_some(&new_bio)) {
            profile.bio = option::some(option::extract(&mut new_bio));
        };
        if (option::is_some(&new_avatar)) {
            profile.avatar = option::some(option::extract(&mut new_avatar));
        };
    }

    public fun delete_profile(profile: DeveloperProfile, _ctx: &mut tx_context::TxContext) {
        let DeveloperProfile {
            id,
            owner: _,
            display_name: _,
            bio: _,
            avatar: _,
            banner: _,
            verified_by: _,
        } = profile;

        object::delete(id);
    }
}