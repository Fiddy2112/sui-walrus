#[test_only]
module profiles::profiles_tests {
    use std::string;
    use std::option;
    use sui::test_scenario;
    use sui::tx_context;
    use profiles::profiles;

    #[test]
    fun test_create_update_delete_profile() {
        // 🔧 Tạo địa chỉ giả (sender)
        let sender = @0xBEEF;
        
        let mut scenario = test_scenario::begin(sender);


        let ctx = test_scenario::ctx(&mut scenario);


        profiles::create_profile(
            ctx,
            string::utf8(b"Dev Bro"),
            option::some(string::utf8(b"Blockchain & AI")),
            option::none<string::String>(),
        );


        let [profile] = test_scenario::take_from_sender<profiles::DeveloperProfile>(&mut scenario, sender);

        let mut new_name = option::some(string::utf8(b"Updated Bro"));
        let mut new_bio = option::some(string::utf8(b"Updated Bio"));
        let mut new_avatar = option::none<string::String>();
        profiles::update_profile(&mut profile, new_name, new_bio, new_avatar);

        profiles::delete_profile(profile, ctx);
        test_scenario::end(scenario);
    }
}
