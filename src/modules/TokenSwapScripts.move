// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x598b8cbfd4536ecbe88aa1cfaffa7a62 {
module TokenSwapScripts {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter2P;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter3P;

    /// register swap for admin user
    public(script) fun register_swap_pair<X :store, Y: store>(account: signer) {
        TokenSwapRouter::register_swap_pair<X, Y>(&account);
    }

    ///
    /// Add liquidity for user
    ///
    public (script) fun add_liquidity<X: store, Y: store>(
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
    public (script) fun remove_liquidity<X: store, Y: store>(
        signer: signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ) {
        TokenSwapRouter::remove_liquidity<X, Y>(
            &signer, liquidity, amount_x_min, amount_y_min);
    }


    public(script) fun swap_exact_token_for_token<X: store, Y: store>(
        signer: signer,
        amount_x_in: u128,
        amount_y_out_min: u128,
    ) {
        TokenSwapRouter::swap_exact_token_for_token<X, Y>(&signer, amount_x_in, amount_y_out_min);
    }

//    public (script) fun swap_exact_token_for_token_router01<X: store, Y: store>(
//        signer: signer,
//        amount_x_in: u128,
//        amount_y_out_min: u128,
//    ) {
//         TokenSwapRouter::swap_exact_token_for_token_router01<X, Y>(&signer, amount_x_in, amount_y_out_min);
//    }

    public(script) fun swap_exact_token_for_token_router02<X: store, R: store, Y: store>(
        signer: signer,
        amount_x_in: u128,
        amount_y_out_min: u128,
    ) {
        //TokenSwapRouter::swap_exact_token_for_token_router02<X, R, Y>(&signer, amount_x_in, amount_y_out_min);
        TokenSwapRouter2P::swap_exact_token_for_token<X, R, Y>(&signer, amount_x_in, amount_y_out_min);
    }

    public(script) fun swap_exact_token_for_token_router03<X: store, R: store, T: store, Y: store>(
        signer: signer,
        amount_x_in: u128,
        amount_y_out_min: u128,
    ) {
        //TokenSwapRouter::swap_exact_token_for_token_router03<X, R, T, Y>(&signer, amount_x_in, amount_y_out_min);
        TokenSwapRouter3P::swap_exact_token_for_token<X, R, T, Y>(&signer, amount_x_in, amount_y_out_min);
    }


    public (script) fun swap_token_for_exact_token<X: store, Y: store>(
        signer: signer,
        amount_x_in_max: u128,
        amount_y_out: u128,
    ) {
        TokenSwapRouter::swap_token_for_exact_token<X, Y>(&signer, amount_x_in_max, amount_y_out);
    }

//    public (script) fun swap_token_for_exact_token_router01<X: store, Y: store>(
//        signer: signer,
//        amount_x_in_max: u128,
//        amount_y_out: u128,
//    ) {
//        TokenSwapRouter::swap_token_for_exact_token_router01<X, Y>(&signer, amount_x_in_max, amount_y_out);
//    }

    public fun swap_token_for_exact_token_router02<X: store, R: store, Y: store>(
        signer: signer,
        amount_x_in_max: u128,
        amount_y_out: u128,
    ) {
        //TokenSwapRouter::swap_token_for_exact_token_router02<X, R, Y>(&signer, amount_x_in_max, amount_y_out);
        TokenSwapRouter3P::swap_token_for_exact_token<X, R, Y>(&signer, amount_x_in_max, amount_y_out);
    }

    public fun swap_token_for_exact_token_router03<X: store, R: store, T: store, Y: store>(
        signer: signer,
        amount_x_in_max: u128,
        amount_y_out: u128,
    ) {
        //TokenSwapRouter::swap_token_for_exact_token_router03<X, R, T, Y>(&signer, amount_x_in_max, amount_y_out);
        TokenSwapRouter3P::swap_token_for_exact_token<X, R, T, Y>(&signer, amount_x_in_max, amount_y_out);
    }

}
}