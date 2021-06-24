// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

address 0x569ab535990a17ac9afd1bc57faec683 {
module TokenSwapScripts {
    use 0x1::Signer;
    use 0x1::Debug;
    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwapRouter;

    /// register swap for admin user
    public(script) fun register_swap_pair<X :store, Y: store>(account: signer) {
        TokenSwapRouter::register_swap_pair<X, Y>(&account);
    }

    ///
    /// Query liquidity of user
    //
    public(script) fun liquidity<X: store, Y: store>(account: signer) {
        let liquidity = TokenSwapRouter::liquidity<X, Y>(Signer::address_of(&account));
        Debug::print<u128>(&liquidity);
    }

    ///
    /// Query Total liquidity of global
    //
    public(script) fun total_liquidity<X: store, Y: store>() {
        TokenSwapRouter::total_liquidity<X, Y>();
    }

    ///
    /// Add liquidity for user
    ///
    public(script) fun add_liquidity<X: store, Y: store>(
        signer: signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128) {
        TokenSwapRouter::add_liquidity<X, Y>(
            &signer, amount_x_desired, amount_y_desired, amount_x_min, amount_y_min);
    }

    ///
    /// Remove liquidity for user
    ///
    public(script) fun remove_liquidity<X: store, Y: store>(
        signer: signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ) {
        TokenSwapRouter::remove_liquidity<X, Y>(
            &signer, liquidity, amount_x_min, amount_y_min);
    }

    public(script) fun liquidity<X: store, Y: store>(account: address): u128 {
        TokenSwapRouter::liquidity<X,Y>(account)
    }

    public(script) fun total_liquidity<X: store, Y: store>(): u128 {
        TokenSwapRouter::total_liquidity<X,Y>()
    }

    public(script) fun swap_exact_token_for_token<X: store, Y: store>(
        signer: signer,
        amount_x_in: u128,
        amount_y_out_min: u128,
    ) {
        TokenSwapRouter::swap_exact_token_for_token<X,Y>(&signer, amount_x_in, amount_y_out_min)
    }

    public(script) fun swap_token_for_exact_token<X: store, Y: store>(
        signer: signer,
        amount_x_in_max: u128,
        amount_y_out: u128,
    ) {
        TokenSwapRouter::swap_token_for_exact_token<X,Y>(&signer, amount_x_in_max, amount_y_out)
    }

    public(script) fun get_reserves<X: store, Y: store>(): (u128, u128) {
        TokenSwapRouter::get_reserves<X,Y>()
    }

    public(script) fun quote(amount_x: u128, reserve_x: u128, reserve_y: u128): u128 {
        TokenSwapRouter::quote(amount_x, reserve_x, reserve_y)
    }

    public(script) fun get_amount_out(amount_in: u128, reserve_in: u128, reserve_out: u128): u128 {
        TokenSwapRouter::get_amount_out(amount_in, reserve_in, reserve_out)
    }

    public(script) fun get_amount_in(amount_out: u128, reserve_in: u128, reserve_out: u128): u128 {
        TokenSwapRouter::get_amount_in(amount_out, reserve_in, reserve_out)
    }
}
}