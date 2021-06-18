// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

script {
    use 0x1::TokenSwapGateway;

    fun do_it<X: store, Y: store>(account: signer,
                                  amount_x_desired: u128,
                                  amount_y_desired: u128,
                                  amount_x_min: u128,
                                  amount_y_min: u128) {
        TokenSwapGateway::add_liquidity<X, Y>(
            &account,
            amount_x_desired,
            amount_y_desired,
            amount_x_min,
            amount_y_min);
    }
}
