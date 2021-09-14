// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x598b8cbfd4536ecbe88aa1cfaffa7a62 {
module TokenSwapRouter2 {

    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapRouter;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapLibrary;

    const ERROR_ROUTER_PARAMETER_INVALID: u64 = 1001;
    const ERROR_ROUTER_Y_OUT_LESSTHAN_EXPECTED: u64 = 1002;
    const ERROR_ROUTER_X_IN_OVER_LIMIT_MAX: u64 = 1003;

    public fun get_amount_in<X: store, R: store, Y: store>(amount_y_out: u128): (u128, u128) {
        let (reserve_r, reserve_y) = TokenSwapRouter::get_reserves<R, Y>();
        let r_in = TokenSwapLibrary::get_amount_in(amount_y_out, reserve_r, reserve_y);

        let (reserve_x, reserve_r) = TokenSwapRouter::get_reserves<X, R>();
        let x_in = TokenSwapLibrary::get_amount_in(r_in, reserve_x, reserve_r);

        (r_in, x_in)
    }

    public fun get_amount_out<X: store, R: store, Y: store>(amount_x_in: u128): (u128, u128) {
        let (reserve_x, reserve_r) = TokenSwapRouter::get_reserves<X, R>();
        let r_out = TokenSwapLibrary::get_amount_out(amount_x_in, reserve_x, reserve_r);

        let (reserve_r, reserve_y) = TokenSwapRouter::get_reserves<R, Y>();
        let y_out = TokenSwapLibrary::get_amount_out(r_out, reserve_r, reserve_y);

        (r_out, y_out)
    }

    public fun swap_exact_token_for_token<X: store, R: store, Y: store>(
        signer: &signer,
        amount_x_in: u128,
        amount_y_out_min: u128) {
        // calculate actual y out
        let (r_out, y_out) = get_amount_out<X, R, Y>(amount_x_in);
        assert(y_out >= amount_y_out_min, ERROR_ROUTER_Y_OUT_LESSTHAN_EXPECTED);

        TokenSwapRouter::swap_exact_token_for_token<X, R>(signer, amount_x_in, r_out);
        TokenSwapRouter::swap_exact_token_for_token<R, Y>(signer, r_out, amount_y_out_min);
    }

    public fun swap_token_for_exact_token<X: store, R: store, Y: store>(
        signer: &signer,
        amount_x_in_max: u128,
        amount_y_out: u128) {
        // calculate actual x in
        let (r_in, x_in) = get_amount_in<X, R, Y>(amount_y_out);
        assert(x_in <= amount_x_in_max, ERROR_ROUTER_X_IN_OVER_LIMIT_MAX);

        // do actual swap
        TokenSwapRouter::swap_token_for_exact_token<X, R>(signer, amount_x_in_max, r_in);
        TokenSwapRouter::swap_token_for_exact_token<R, Y>(signer, r_in, amount_y_out);
    }
}
}