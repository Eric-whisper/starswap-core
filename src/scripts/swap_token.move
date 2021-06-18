// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

script {
    use 0x1::TokenSwapGateway;

    fun swap_token<X: store, Y: store>(account: signer,
                                       amount_x_in: u128,
                                       amount_y_out_min: u128) {
        TokenSwapGateway::swap_exact_token_for_token<X, Y>(
            &account,
            amount_x_in,
            amount_y_out_min);
    }
}

script {
    use 0x1::TokenSwapGateway;

    fun quer_reverse<X: store, Y: store>() {
        TokenSwapGateway::get_reserves<X, Y>();
    }
}
