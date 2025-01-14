// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED
//

script {
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;

    fun main<X: store, Y: store>(account: signer,
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
