// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x598b8cbfd4536ecbe88aa1cfaffa7a62 {
module TokenSwapRouter {
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwap::{LiquidityToken, Self};
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::Token;
    use 0x598b8cbfd4536ecbe88aa1cfaffa7a62::TokenSwapLibrary;
    use 0x49156896A605F092ba1862C50a9036c9::BX_USDT::BX_USDT;

    // use 0x1::Debug;
    const ERROR_ROUTER_PARAMETER_INVALID: u64 = 1001;
    const ERROR_ROUTER_INSUFFICIENT_X_AMOUNT: u64 = 1002;
    const ERROR_ROUTER_INSUFFICIENT_Y_AMOUNT: u64 = 1003;
    const ERROR_ROUTER_INVALID_TOKEN_PAIR: u64 = 1004;
    const ERROR_ROUTER_OVERLIMIT_X_DESIRED: u64 = 1005;
    const ERROR_ROUTER_Y_OUT_LESSTHAN_EXPECTED: u64 = 1006;
    const ERROR_ROUTER_X_IN_OVER_LIMIT_MAX: u64 = 1007;
    const ERROR_ROUTER_ADD_LIQUIDITY_FAILED: u64 = 1008;
    const ERROR_ROUTER_WITHDRAW_INSUFFICIENT: u64 = 1009;
    const ERROR_ROUTER_SWAP_ROUTER_PAIR_INVALID: u64 = 1010;
    const ERROR_ROUTER_SWAP_FEE_MUST_POSITIVE: u64 = 1011;


    ///swap router depth
    const ROUTER_SWAP_ROUTER_DEPTH_ONE: u64 = 1;
    const ROUTER_SWAP_ROUTER_DEPTH_TWO: u64 = 2;
    const ROUTER_SWAP_ROUTER_DEPTH_THREE: u64 = 3;


    ///
    /// Check if swap pair exists
    ///
    public fun swap_pair_exists<X: store, Y: store>(): bool {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenSwap::swap_pair_exists<X, Y>()
        } else {
            TokenSwap::swap_pair_exists<Y, X>()
        }
    }

    ///
    /// Swap token auto accept
    ///
    public fun swap_pair_token_auto_accept<Token: store>(signer: &signer) {
        if (!Account::is_accepts_token<Token>(Signer::address_of(signer))) {
            Account::do_accept_token<Token>(signer);
        };
    }

    ///
    /// Register swap pair by comparing sort
    ///
    public fun register_swap_pair<X: store, Y: store>(account: &signer) {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenSwap::register_swap_pair<X, Y>(account)
        } else {
            TokenSwap::register_swap_pair<Y, X>(account)
        }
    }


    public fun liquidity<X: store, Y: store>(account: address): u128 {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            Account::balance<LiquidityToken<X, Y>>(account)
        } else {
            Account::balance<LiquidityToken<Y, X>>(account)
        }
    }

    public fun total_liquidity<X: store, Y: store>(): u128 {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            Token::market_cap<LiquidityToken<X, Y>>()
        } else {
            Token::market_cap<LiquidityToken<Y, X>>()
        }
    }

    public fun add_liquidity<X: store, Y: store>(
        signer: &signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ) {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            intra_add_liquidity<X, Y>(
                signer,
                amount_x_desired,
                amount_y_desired,
                amount_x_min,
                amount_y_min,
            );
        } else {
            intra_add_liquidity<Y, X>(
                signer,
                amount_y_desired,
                amount_x_desired,
                amount_y_min,
                amount_x_min,
            );
        }
    }

    fun intra_add_liquidity<X: store, Y: store>(
        signer: &signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ) {
        let (amount_x, amount_y) = intra_calculate_amount_for_liquidity<X, Y>(
            amount_x_desired,
            amount_y_desired,
            amount_x_min,
            amount_y_min,
        );
        let x_token = Account::withdraw<X>(signer, amount_x);
        let y_token = Account::withdraw<Y>(signer, amount_y);

        let liquidity_token = TokenSwap::mint<X, Y>(x_token, y_token);
        if (!Account::is_accepts_token<LiquidityToken<X, Y>>(Signer::address_of(signer))) {
            Account::do_accept_token<LiquidityToken<X, Y>>(signer);
        };

        // emit liquidity event
        let liquidity: u128 = Token::value<LiquidityToken<X, Y>>(&liquidity_token);
        assert(liquidity > 0, ERROR_ROUTER_ADD_LIQUIDITY_FAILED);
        TokenSwap::emit_liquidity_event<X, Y>(signer, liquidity);

        Account::deposit(Signer::address_of(signer), liquidity_token);
    }

    fun intra_calculate_amount_for_liquidity<X: store, Y: store>(
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ): (u128, u128) {
        let (reserve_x, reserve_y) = get_reserves<X, Y>();
        if (reserve_x == 0 && reserve_y == 0) {
            return (amount_x_desired, amount_y_desired)
        } else {
            let amount_y_optimal = TokenSwapLibrary::quote(amount_x_desired, reserve_x, reserve_y);
            if (amount_y_optimal <= amount_y_desired) {
                assert(amount_y_optimal >= amount_y_min, ERROR_ROUTER_INSUFFICIENT_Y_AMOUNT);
                return (amount_x_desired, amount_y_optimal)
            } else {
                let amount_x_optimal = TokenSwapLibrary::quote(amount_y_desired, reserve_y, reserve_x);
                assert(amount_x_optimal <= amount_x_desired, ERROR_ROUTER_OVERLIMIT_X_DESIRED);
                assert(amount_x_optimal >= amount_x_min, ERROR_ROUTER_INSUFFICIENT_X_AMOUNT);
                return (amount_x_optimal, amount_y_desired)
            }
        }
    }

    public fun remove_liquidity<X: store, Y: store>(
        signer: &signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ) {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            intra_remove_liquidity<X, Y>(signer, liquidity, amount_x_min, amount_y_min);
        } else {
            intra_remove_liquidity<Y, X>(signer, liquidity, amount_y_min, amount_x_min);
        }
    }

    fun intra_remove_liquidity<X: store, Y: store>(
        signer: &signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128,
    ) {
        let liquidity_token = Account::withdraw<LiquidityToken<X, Y>>(signer, liquidity);
        let (token_x, token_y) = TokenSwap::burn(liquidity_token);
        assert(Token::value(&token_x) >= amount_x_min, ERROR_ROUTER_INSUFFICIENT_X_AMOUNT);
        assert(Token::value(&token_y) >= amount_y_min, ERROR_ROUTER_INSUFFICIENT_Y_AMOUNT);
        Account::deposit(Signer::address_of(signer), token_x);
        Account::deposit(Signer::address_of(signer), token_y);
    }

    public fun swap_exact_token_for_token<X: store, Y: store>(
        signer: &signer,
        amount_x_in: u128,
        amount_y_out_min: u128,
    ) {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);

        // auto accept swap token
        swap_pair_token_auto_accept<Y>(signer);
        // calculate actual y out
        let (reserve_x, reserve_y) = get_reserves<X, Y>();
        let y_out = TokenSwapLibrary::get_amount_out(amount_x_in, reserve_x, reserve_y);
        assert(y_out >= amount_y_out_min, ERROR_ROUTER_Y_OUT_LESSTHAN_EXPECTED);

        // do actual swap
        let token_x = Account::withdraw<X>(signer, amount_x_in);
        let (token_x_out, token_y_out);
        if (order == 1) {
            (token_x_out, token_y_out) = TokenSwap::swap<X, Y>(token_x, y_out, Token::zero(), 0);
        } else {
            (token_y_out, token_x_out) = TokenSwap::swap<Y, X>(Token::zero(), 0, token_x, y_out);
        };
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);

        //swap fee setup
        if(TokenSwap::get_swap_fee_on()) {
            swap_exact_token_for_token_swap_fee_setup<X, Y>(amount_x_in, y_out, reserve_x, reserve_y);
        }

    }

    /// use the last (reserve_x, reserve_y), (new_reserve_x, reserve_y_new) has changed
    public fun swap_exact_token_for_token_swap_fee_setup<X: store, Y: store>(amount_x_in: u128, y_out: u128, reserve_x: u128, reserve_y: u128) {
        // swap fee setup, use Y token to pay for fee
        let y_out_without_fee = TokenSwapLibrary::get_amount_out_without_fee(amount_x_in, reserve_x, reserve_y);
        let swap_fee = y_out_without_fee - y_out;
        assert(swap_fee > 0, ERROR_ROUTER_SWAP_FEE_MUST_POSITIVE);

        intra_swap_fee_setup<X, Y, Y, BX_USDT>(swap_fee, false);
    }

    public fun swap_token_for_exact_token<X: store, Y: store>(
        signer: &signer,
        amount_x_in_max: u128,
        amount_y_out: u128,
    ) {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);

        // auto accept swap token
        swap_pair_token_auto_accept<Y>(signer);
        // calculate actual x in
        let (reserve_x, reserve_y) = get_reserves<X, Y>();
        let x_in = TokenSwapLibrary::get_amount_in(amount_y_out, reserve_x, reserve_y);
        assert(x_in <= amount_x_in_max, ERROR_ROUTER_X_IN_OVER_LIMIT_MAX);

        // do actual swap
        let token_x = Account::withdraw<X>(signer, x_in);
        let (token_x_out, token_y_out);
        if (order == 1) {
            (token_x_out, token_y_out) =
                TokenSwap::swap<X, Y>(token_x, amount_y_out, Token::zero(), 0);
        } else {
            (token_y_out, token_x_out) =
                TokenSwap::swap<Y, X>(Token::zero(), 0, token_x, amount_y_out);
        };
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);

        //swap fee setup
        if(TokenSwap::get_swap_fee_on()) {
            swap_token_for_exact_token_swap_fee_setup<X, Y>(x_in, amount_y_out, reserve_x, reserve_y);
        }
    }

    public fun swap_token_for_exact_token_swap_fee_setup<X: store, Y: store>(x_in: u128, amount_y_out: u128, reserve_x: u128, reserve_y: u128) {
        // swap fee setup, use X token to pay for fee
        let x_in_without_fee = TokenSwapLibrary::get_amount_in_without_fee(amount_y_out, reserve_x, reserve_y);
        let swap_fee = x_in - x_in_without_fee;
        assert(swap_fee > 0, ERROR_ROUTER_SWAP_FEE_MUST_POSITIVE);

        intra_swap_fee_setup<X, Y, X, BX_USDT>(swap_fee, true);
    }

    fun intra_swap_fee_setup<X: store, Y: store, P: store, Q: store>(
        swap_fee: u128,
        x_pay_for_fee: bool){
        // fee token and the token to pay for fee compare
        let fee_order = TokenSwap::compare_token<P, Q>();
        // the token to pay for fee, is fee token
        if (fee_order == 0) {
            TokenSwap::swap_fee_direct<X, Y>(swap_fee, x_pay_for_fee);
        } else {
            // check [P, Q] token pair exist
            let fee_token_pair_exist = swap_pair_exists<P, Q>();
            if (fee_token_pair_exist) {
                let (reserve_p, reserve_q) = get_reserves<P, Q>();
                let fee_out = TokenSwapLibrary::get_amount_out_without_fee(swap_fee, reserve_p, reserve_q);
                TokenSwap::swap_fee_swap<X, Y, Q>(swap_fee, fee_out, x_pay_for_fee);
            }else{
                //TODO swap fee retention in LP pool
            }
        };
    }

    /// Get reserves of a token pair.
    /// The order of `X`, `Y` doesn't need to be sorted.
    /// And the order of return values are based on the order of type parameters.
    public fun get_reserves<X: store, Y: store>(): (u128, u128) {
        let order = TokenSwap::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenSwap::get_reserves<X, Y>()
        } else {
            let (y, x) = TokenSwap::get_reserves<Y, X>();
            (x, y)
        }
    }

    /// Withdraw liquidity from users
    public fun withdraw_liquidity_token<X: store, Y: store>(account: &signer,
                                                            amount: u128): Token::Token<LiquidityToken<X, Y>> {
        let user_liquidity = liquidity<X, Y>(Signer::address_of(account));
        assert(user_liquidity <= amount, ERROR_ROUTER_WITHDRAW_INSUFFICIENT);

        Account::withdraw<LiquidityToken<X, Y>>(account, amount)
    }

    /// Deposit liquidity token into user source list
    public fun deposit_liquidity_token<X: store, Y: store>(account: address,
                                                           to_deposit: Token::Token<LiquidityToken<X, Y>>) {
        Account::deposit<LiquidityToken<X, Y>>(account, to_deposit);
    }
}
}