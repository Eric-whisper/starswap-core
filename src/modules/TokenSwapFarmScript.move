// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x598b8cbfd4536ecbe88aa1cfaffa7a62 {
module TokenSwapFarmScript {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapFarmRouter;

    /// Called by admin account
    public(script) fun add_farm_pool<TokenX: store, TokenY: store>(account: signer, release_per_second: u128) {
        TokenSwapFarmRouter::add_farm_pool<TokenX, TokenY>(&account, release_per_second);
    }

    /// Stake liquidity token
    public(script) fun stake<TokenX: store, TokenY: store>(account: signer, amount: u128) {
        TokenSwapFarmRouter::stake<TokenX, TokenY>(&account, amount);
    }

    /// Unstake liquidity token
    public(script) fun unstake<TokenX: store, TokenY: store>(account: signer) {
        TokenSwapFarmRouter::unstake<TokenX, TokenY>(&account);
    }

    /// Havest governance token from pool
    public(script) fun harvest<TokenX: store, TokenY: store>(account: signer, amount: u128) {
        TokenSwapFarmRouter::harvest<TokenX, TokenY>(&account, amount);
    }

    /// Get gain count
    public fun lookup_gain<TokenX: store, TokenY: store>(account: signer): u128 {
        TokenSwapFarmRouter::lookup_gain<TokenX, TokenY>(&account)
    }

    /// Query all stake amount
    public fun query_total_stake<TokenX: store, TokenY: store>(): u128 {
        TokenSwapFarmRouter::query_total_stake<TokenX, TokenY>()
    }

    /// Query all stake amount
    public fun query_stake<TokenX: store, TokenY: store>(account: signer): u128 {
        TokenSwapFarmRouter::query_stake<TokenX, TokenY>(&account)
    }

    /// Query release per second
    public fun query_release_per_second<TokenX: store, TokenY: store>(): u128 {
        TokenSwapFarmRouter::query_release_per_second<TokenX, TokenY>()
    }

    /// Lookup APY
    public fun apy<TokenX: store, TokenY: store>(): u128 {
        TokenSwapFarmRouter::apy<TokenX, TokenY>()
    }
}
}