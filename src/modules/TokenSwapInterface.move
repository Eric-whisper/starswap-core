// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

address 0x569ab535990a17ac9afd1bc57faec683 {
module TokenSwapInterface {

    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwap;
    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwapGateway;

    /// register swap for admin user
    public(script) fun register_swap_pair<X :store, Y: store>(account: signer) {
        TokenSwapGateway::register_swap_pair<X, Y>(&account);
    }

    /// add liquidity for user
    public(script) fun add_liquidity<X: store, Y: store>(
        signer: signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128) {
        TokenSwapGateway::add_liquidity<X, Y>(
            &signer, amount_x_desired, amount_y_desired, amount_x_min, amount_y_min);
    }

    /// remove liquidity for user
    public(script) fun remove_liquidity<X: store, Y: store>(
        signer: signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ) {
        TokenSwapGateway::remove_liquidity<X, Y>(
            &signer, liquidity, amount_x_min, amount_y_min);
    }

    ///
    /// test function for compare
    public(script) fun compare_token<X: store, Y: store>() {
        assert(TokenSwap::compare_token<X, Y>() == 0 , 10001);
    }
}
}