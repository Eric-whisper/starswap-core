// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapFarmScript {
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapFarm;

    const ERROR_ROUTER_INVALID_TOKEN_PAIR: u64 = 5001;

    /// Called by admin account
    public(script) fun add_farm_pool<TokenX: store, TokenY: store>(account: signer, release_per_second: u128) {
        let order = TokenSwap::compare_token<TokenX, TokenY>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenSwapFarm::add_farm<TokenX, TokenY>(&account, release_per_second);
        } else {
            TokenSwapFarm::add_farm<TokenY, TokenX>(&account, release_per_second);
        };
    }

    /// Stake liquidity token
    public(script) fun stake<TokenX: store, TokenY: store>(account: signer, amount: u128) {
        let order = TokenSwap::compare_token<TokenX, TokenY>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenSwapFarm::stake<TokenX, TokenY>(&account, amount);
        } else {
            TokenSwapFarm::stake<TokenY, TokenX>(&account, amount);
        }
    }

    /// Unstake liquidity token
    public(script) fun unstake<TokenX: store, TokenY: store>(account: signer, amount: u128) {
        let order = TokenSwap::compare_token<TokenX, TokenY>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenSwapFarm::unstake<TokenX, TokenY>(&account, amount);
        } else {
            TokenSwapFarm::unstake<TokenY, TokenX>(&account, amount);
        }

    }

    /// Havest governance token from pool
    public(script) fun harvest<TokenX: store, TokenY: store>(account: signer, amount: u128) {
        let order = TokenSwap::compare_token<TokenX, TokenY>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenSwapFarm::harvest<TokenX, TokenY>(&account, amount);
        } else {
            TokenSwapFarm::harvest<TokenY, TokenX>(&account, amount);
        }
    }
}
}