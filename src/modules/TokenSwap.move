// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x598b8cbfd4536ecbe88aa1cfaffa7a62 {

/// Token Swap
module TokenSwap {
    use 0x1::Token;
    use 0x1::Signer;
    use 0x1::Math;
    use 0x1::Compare;
    use 0x1::BCS;
    use 0x1::Timestamp;
    use 0x1::Event;
    use 0x1::Account;

    struct LiquidityToken<X, Y> has key, store { }

    struct LiquidityTokenCapability<X, Y> has key, store {
        mint: Token::MintCapability<LiquidityToken<X, Y>>,
        burn: Token::BurnCapability<LiquidityToken<X, Y>>,
    }

    /// Event emitted when token added liquidity.
    struct AddLiquidityEvent has drop, store {
        /// liquidity value by user X and Y type
        liquidity: u128,
        /// token code of X type
        x_token_code: Token::TokenCode,
        /// token code of X type
        y_token_code: Token::TokenCode,
        /// signer of add liquidity
        signer: address,
    }

    struct TokenPair<X, Y> has key, store  {
        token_x_reserve: Token::Token<X>,
        token_y_reserve: Token::Token<Y>,
        last_block_timestamp: u64,
        last_price_x_cumulative: u128,
        last_price_y_cumulative: u128,
        last_k: u128,
        add_liquidity_event: Event::EventHandle<AddLiquidityEvent>,
    }

    const ERROR_SWAP_INVALID_TOKEN_PAIR: u64 = 2000;
    const ERROR_SWAP_INVALID_PARAMETER: u64 = 2001;
    const ERROR_SWAP_TOKEN_INSUFFICIENT: u64 = 2002;
    const ERROR_SWAP_DUPLICATE_TOKEN: u64 = 2003;
    const ERROR_SWAP_BURN_CALC_INVALID: u64 = 2004;
    const ERROR_SWAP_SWAPOUT_CALC_INVALID: u64 = 2005;
    const ERROR_SWAP_PRIVILEGE_INSUFFICIENT: u64 = 2006;
    const ERROR_SWAP_ADDLIQUIDITY_INVALID: u64 = 2007;
    const ERROR_SWAP_TOKEN_NOT_EXISTS: u64 = 2008;
    const ERROR_SWAP_TOKEN_FEE_INVALID: u64 = 2009;

    const SWAP_FEE_ON: bool= false;

    ///
    /// Check if swap pair exists
    ///
    public fun swap_pair_exists<X: store, Y: store>() : bool {
        let order = compare_token<X, Y>();
        assert(order != 0, ERROR_SWAP_INVALID_TOKEN_PAIR);
        Token::is_registered_in<LiquidityToken<X, Y>>(admin_address())
    }

    // for now, only admin can register token pair
    public fun register_swap_pair<X: store, Y: store>(signer: &signer) {
        // check X,Y is token.
        //assert_is_token<X>();
        //assert_is_token<Y>();

        let order = compare_token<X, Y>();
        assert(order != 0, ERROR_SWAP_INVALID_TOKEN_PAIR);
        assert_admin(signer);
        let token_pair = make_token_pair<X, Y>(signer);
        move_to(signer, token_pair);
        register_liquidity_token<X, Y>(signer);
    }

    fun register_liquidity_token<X: store, Y: store>(signer: &signer) {
        assert_admin(signer);
        Token::register_token<LiquidityToken<X, Y>>(signer, 18);
        let mint_capability = Token::remove_mint_capability<LiquidityToken<X, Y>>(signer);
        let burn_capability = Token::remove_burn_capability<LiquidityToken<X, Y>>(signer);
        move_to(signer, LiquidityTokenCapability { mint: mint_capability, burn: burn_capability });
    }

    fun make_token_pair<X: store, Y: store>(signer: &signer): TokenPair<X, Y> {
        // assert X, Y is token
        //assert_is_token<X>();
        //assert_is_token<Y>();

        TokenPair<X, Y> {
            token_x_reserve: Token::zero<X>(),
            token_y_reserve: Token::zero<Y>(),
            last_block_timestamp: 0,
            last_price_x_cumulative: 0,
            last_price_y_cumulative: 0,
            last_k: 0,
            add_liquidity_event: Event::new_event_handle<AddLiquidityEvent>(signer),
        }
    }

    /// Liquidity Provider's methods
    /// type args, X, Y should be sorted.
    public fun mint<X: store, Y: store>(
        x: Token::Token<X>,
        y: Token::Token<Y>,
    ): Token::Token<LiquidityToken<X, Y>> acquires TokenPair, LiquidityTokenCapability {
        let total_supply: u128 = Token::market_cap<LiquidityToken<X, Y>>();
        let (x_reserve, y_reserve) = get_reserves<X, Y>();
        let x_value = Token::value<X>(&x);
        let y_value = Token::value<Y>(&y);
        let liquidity = if (total_supply == 0) {
            // 1000 is the MINIMUM_LIQUIDITY
            (Math::sqrt((x_value as u128) * (y_value as u128)) as u128) - 1000
        } else {
//            let token_pair = borrow_global<TokenPair<X, Y>>(admin_address());
            // let x_reserve = Token::value(&token_pair.token_x_reserve);
            // let y_reserve = Token::value(&token_pair.token_y_reserve);
            let x_liquidity = x_value * total_supply / x_reserve;
            let y_liquidity = y_value * total_supply / y_reserve;
            // use smaller one.
            if (x_liquidity < y_liquidity) {
                x_liquidity
            } else {
                y_liquidity
            }
        };
        assert(liquidity > 0, ERROR_SWAP_ADDLIQUIDITY_INVALID);
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());
        Token::deposit(&mut token_pair.token_x_reserve, x);
        Token::deposit(&mut token_pair.token_y_reserve, y);
        let liquidity_cap = borrow_global<LiquidityTokenCapability<X, Y>>(admin_address());
        let mint_token = Token::mint_with_capability(&liquidity_cap.mint, liquidity);
        update_token_pair<X,Y>(x_reserve, y_reserve);

        mint_token
    }


    ///
    /// Emit liquidity event
    ///
    public fun emit_liquidity_event<X: store, Y:store>(signer: &signer, liquidity: u128):() acquires TokenPair {
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());
        Event::emit_event(&mut token_pair.add_liquidity_event,
            AddLiquidityEvent {
                liquidity,
                y_token_code: Token::token_code<Y>(),
                x_token_code: Token::token_code<X>(),
                signer: Signer::address_of(signer),
            });
    }


    public fun burn<X: store, Y: store>(
        to_burn: Token::Token<LiquidityToken<X, Y>>,
    ): (Token::Token<X>, Token::Token<Y>) acquires TokenPair, LiquidityTokenCapability {
        let to_burn_value = (Token::value(&to_burn) as u128);
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());
        let x_reserve = (Token::value(&token_pair.token_x_reserve) as u128);
        let y_reserve = (Token::value(&token_pair.token_y_reserve) as u128);
        let total_supply = Token::market_cap<LiquidityToken<X, Y>>();
        let x = to_burn_value * x_reserve / total_supply;
        let y = to_burn_value * y_reserve / total_supply;
        assert(x > 0 && y > 0, ERROR_SWAP_BURN_CALC_INVALID);
        burn_liquidity(to_burn);
        let x_token = Token::withdraw(&mut token_pair.token_x_reserve, x);
        let y_token = Token::withdraw(&mut token_pair.token_y_reserve, y);
        update_token_pair<X,Y>(x_reserve, y_reserve);
        (x_token, y_token)
    }

    fun burn_liquidity<X: store, Y: store>(to_burn: Token::Token<LiquidityToken<X, Y>>)
    acquires LiquidityTokenCapability {
        let liquidity_cap = borrow_global<LiquidityTokenCapability<X, Y>>(admin_address());
        Token::burn_with_capability<LiquidityToken<X, Y>>(&liquidity_cap.burn, to_burn);
    }

    //// User methods ////////

    /// Get reserves of a token pair.
    /// The order of type args should be sorted.
    public fun get_reserves<X: store, Y: store>(): (u128, u128) acquires TokenPair {
        let token_pair = borrow_global<TokenPair<X, Y>>(admin_address());
        let x_reserve = Token::value(&token_pair.token_x_reserve);
        let y_reserve = Token::value(&token_pair.token_y_reserve);
//        let last_block_timestamp = token_pair.last_block_timestamp;
        (x_reserve, y_reserve)
    }

    public fun swap<X: store, Y: store>(
        x_in: Token::Token<X>,
        y_out: u128,
        y_in: Token::Token<Y>,
        x_out: u128,
    ): (Token::Token<X>, Token::Token<Y>) acquires TokenPair {
        do_swap<X, Y>(x_in, y_out, y_in, x_out, true)
    }

    fun do_swap<X: store, Y: store>(
        x_in: Token::Token<X>,
        y_out: u128,
        y_in: Token::Token<Y>,
        x_out: u128,
        with_swap_fee: bool,
    ): (Token::Token<X>, Token::Token<Y>) acquires TokenPair {
        let x_in_value = Token::value(&x_in);
        let y_in_value = Token::value(&y_in);
        assert(x_in_value > 0 || y_in_value > 0, ERROR_SWAP_TOKEN_INSUFFICIENT);
        let (x_reserve, y_reserve) = get_reserves<X, Y>();
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());
        Token::deposit(&mut token_pair.token_x_reserve, x_in);
        Token::deposit(&mut token_pair.token_y_reserve, y_in);
        let x_swapped = Token::withdraw(&mut token_pair.token_x_reserve, x_out);
        let y_swapped = Token::withdraw(&mut token_pair.token_y_reserve, y_out);
            {
                let x_reserve_new = Token::value(&token_pair.token_x_reserve);
                let y_reserve_new = Token::value(&token_pair.token_y_reserve);
                let (x_adjusted, y_adjusted);
                if (with_swap_fee) {
                    x_adjusted = x_reserve_new * 1000 - x_in_value * 3;
                    y_adjusted = y_reserve_new * 1000 - y_in_value * 3;
                } else {
                    x_adjusted = x_reserve_new * 1000;
                    y_adjusted = y_reserve_new * 1000;
                };
                assert(x_adjusted * y_adjusted >= x_reserve * y_reserve * 1000000, ERROR_SWAP_SWAPOUT_CALC_INVALID);
            };

        update_token_pair<X,Y>(x_reserve, y_reserve);
        (x_swapped, y_swapped)
    }


    /// Caller should call this function to determine the order of A, B
    public fun compare_token<X: store, Y: store>(): u8 {
        let x_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<X>());
        let y_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<Y>());
        let ret : u8 = Compare::cmp_bcs_bytes(&x_bytes, &y_bytes);
        ret
    }

    fun assert_admin(signer: &signer) {
        assert(Signer::address_of(signer) == admin_address(), ERROR_SWAP_PRIVILEGE_INSUFFICIENT);
    }

    public fun assert_is_token<TokenType: store>() : bool {
        assert(Token::token_address<TokenType>() != @0x0, ERROR_SWAP_TOKEN_NOT_EXISTS);
        true
    }

    fun admin_address(): address {
        @0x598b8cbfd4536ecbe88aa1cfaffa7a62
        // 0x1
    }

    fun fee_address(): address {
        @0xd231d9da8e37fc3d9ff3f576cf978535
        // 0x1
    }

    public fun get_swap_fee_on(): bool {
        SWAP_FEE_ON
    }

    // TWAP price oracle, include update reserves and, on the first call per block, price accumulators
    fun update_token_pair<X: store, Y: store>(
        x_reserve: u128,
        y_reserve: u128,
    ): () acquires TokenPair{
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());
        // let x_reserve0 = Token::value(&token_pair.token_x_reserve);
        // let y_reserve0 = Token::value(&token_pair.token_y_reserve);
        let last_block_timestamp = token_pair.last_block_timestamp;
        let block_timestamp = Timestamp::now_seconds();
        let time_elapsed = (block_timestamp - last_block_timestamp as u128);
        if (time_elapsed > 0 && x_reserve !=0 && y_reserve != 0){
            //TODO avoid overflow ?
            token_pair.last_price_x_cumulative = token_pair.last_price_x_cumulative + (y_reserve / x_reserve * time_elapsed);
            token_pair.last_price_y_cumulative = token_pair.last_price_y_cumulative + (x_reserve / y_reserve * time_elapsed);
        };

        token_pair.last_block_timestamp = block_timestamp;
    }


    public fun swap_fee_direct<X: store, Y: store>(
        swap_fee: u128,
        x_pay_for_fee : bool,
    ): () acquires TokenPair {
        assert(swap_fee > 0 , ERROR_SWAP_TOKEN_FEE_INVALID);
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());

        // the token to pay for fee, is X or Y
        if (x_pay_for_fee){
            let fee_token = Token::withdraw(&mut token_pair.token_x_reserve, swap_fee);
            Account::deposit(fee_address(), fee_token);
        } else {
            let fee_token = Token::withdraw(&mut token_pair.token_y_reserve, swap_fee);
            Account::deposit(fee_address(), fee_token);
        };
    }

    public fun swap_fee_swap<X: store, Y: store, Q: store>(
        swap_fee: u128,
        fee_out: u128,
        x_pay_for_fee : bool,
    ): () acquires TokenPair {
        assert(swap_fee > 0 && fee_out > 0, ERROR_SWAP_TOKEN_FEE_INVALID);
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());

        // the token to pay for fee is X
        if (x_pay_for_fee) {
            let (pay_for_token_out, fee_token_out);
            let x_in_token = Token::withdraw(&mut token_pair.token_x_reserve, swap_fee);
            // fee token and the token to pay for fee compare
            let fee_order = compare_token<X, Q>();
            if (fee_order == 1 ) {
                (pay_for_token_out, fee_token_out) = do_swap<X, Q>(x_in_token, fee_out, Token::zero(), 0, false);
            } else {
                (fee_token_out, pay_for_token_out) = do_swap<Q, X>(Token::zero(), 0, x_in_token, fee_out, false);
            };
            Token::destroy_zero(pay_for_token_out);
            Account::deposit(fee_address(), fee_token_out);
        } else {
            let (pay_for_token_out, fee_token_out);
            let y_in_token = Token::withdraw(&mut token_pair.token_y_reserve, swap_fee);
            // fee token and the token to pay for fee compare
            let fee_order = compare_token<Y, Q>();
            if (fee_order == 1 ) {
                (pay_for_token_out, fee_token_out) = do_swap<Y, Q>(y_in_token, fee_out, Token::zero(), 0, false);
            } else {
                (fee_token_out, pay_for_token_out) = do_swap<Q, Y>(Token::zero(), 0, y_in_token, fee_out, false);
            };
            Token::destroy_zero(pay_for_token_out);
            Account::deposit(fee_address(), fee_token_out);
        };
    }
}
}