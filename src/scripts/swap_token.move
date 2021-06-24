// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

script {
    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwapRouter;

    fun swap_token<X: store, Y: store>(account: signer,
                                       amount_x_in: u128,
                                       amount_y_out_min: u128) {
        TokenSwapRouter::swap_exact_token_for_token<X, Y>(
            &account,
            amount_x_in,
            amount_y_out_min);
    }
}

script {
    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwapRouter;

    fun quer_reverse<X: store, Y: store>() {
        TokenSwapRouter::get_reserves<X, Y>();
    }
}

script {
    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwapRouter;

    fun add_liquidity<X: store, Y: store>(account: signer,
                                          amount_x_desired: u128,
                                          amount_y_desired: u128,
                                          amount_x_min: u128,
                                          amount_y_min: u128) {
        TokenSwapRouter::add_liquidity<X, Y>(
            &account,
            amount_x_desired,
            amount_y_desired,
            amount_x_min,
            amount_y_min);
    }
}