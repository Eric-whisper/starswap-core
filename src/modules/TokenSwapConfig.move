// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0xbd7e8be8fae9f60f2f5136433e36a091 {
module TokenSwapConfig {
    use 0x1::Config;

    /// Swap pair pool config
    struct TokenSwapConfig has copy, drop, store {
        config_value: u128,
    }

    /// config for test
    public fun initialize(account: &signer, config_value: u128) {
        let swap_config = make_new_config(config_value);
        Config::publish_new_config(account, swap_config);
    }

    /// Check swap test config
    public fun token_swap_config(account: address): u128 {
        let publish_option = Config::get_by_address<TokenSwapConfig>(account);
        publish_option.config_value
    }

    /// Make a new config
    public fun make_new_config(config_value: u128): TokenSwapConfig {
        TokenSwapConfig { config_value }
    }
}
}