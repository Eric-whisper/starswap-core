// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapFarm {
    use 0x1::Signer;
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Event;
    use 0x1::YieldFarming;
    use 0x81144d60492982a45ba93fba47cae988::TBD;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap::LiquidityToken;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGovPoolType::{PoolTypeLiquidityMint};

    /// Event emitted when farm been added
    struct AddFarmEvent has drop, store {
        /// token code of X type
        x_token_code: Token::TokenCode,
        /// token code of X type
        y_token_code: Token::TokenCode,
        /// signer of farm add
        signer: address,
        /// admin address
        admin: address,
    }

    /// Event emitted when stake been called
    struct StakeEvent has drop, store {
        /// token code of X type
        x_token_code: Token::TokenCode,
        /// token code of X type
        y_token_code: Token::TokenCode,
        /// signer of stake user
        signer: address,
        // value of stake user
        amount: u128,
        /// admin address
        admin: address,
    }

    /// Event emitted when unstake been called
    struct UnstakeEvent has drop, store {
        /// token code of X type
        x_token_code: Token::TokenCode,
        /// token code of X type
        y_token_code: Token::TokenCode,
        /// signer of stake user
        signer: address,
        /// admin address
        admin: address,
    }

    struct FarmPoolEvent has key, store {
        add_farm_event_handler: Event::EventHandle<AddFarmEvent>,
        stake_event_handler: Event::EventHandle<StakeEvent>,
        unstake_event_handler: Event::EventHandle<UnstakeEvent>,
    }

    struct FarmParameterModfiyCapability<TokenX, TokenY> has key, store {
        cap: YieldFarming::ParameterModifyCapability<
            PoolTypeLiquidityMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>>,
        release_per_seconds: u128,
    }

    /// Initialize farm big pool
    public fun initialize_farm_pool(account: &signer, token: Token::Token<TBD::TBD>) {
        YieldFarming::initialize<
            PoolTypeLiquidityMint,
            TBD::TBD>(account, token);

        move_to(account, FarmPoolEvent {
            add_farm_event_handler: Event::new_event_handle<AddFarmEvent>(account),
            stake_event_handler: Event::new_event_handle<StakeEvent>(account),
            unstake_event_handler: Event::new_event_handle<UnstakeEvent>(account),
        });
    }

    /// Initialize Liquidity pair gov pool, only called by token issuer
    public fun add_farm<TokenX: store, TokenY: store>(
        account: &signer,
        release_per_seconds: u128) acquires FarmPoolEvent {
        // Only called by the genesis
        TBD::assert_genesis_address(account);

        // To determine how many amount release in every period
        let cap = YieldFarming::initialize_asset<
            PoolTypeLiquidityMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account, release_per_seconds, 0);

        move_to(account, FarmParameterModfiyCapability<TokenX, TokenY> {
            cap,
            release_per_seconds,
        });
//        // TODO (BobOng): Add to DAO
//        GovernanceDaoProposal::plugin<
//            PoolTypeProposal<TokenX, TokenY, GovTokenT>,
//            GovTokenT>(account, modify_cap);

        // Emit add farm event
        let admin = Signer::address_of(account);
        let farm_pool_event = borrow_global_mut<FarmPoolEvent>(admin);
        Event::emit_event(&mut farm_pool_event.add_farm_event_handler,
            AddFarmEvent {
                y_token_code: Token::token_code<TokenX>(),
                x_token_code: Token::token_code<TokenY>(),
                signer: Signer::address_of(account),
                admin,
            });
    }

    /// Stake liquidity Token pair
    public fun stake<TokenX: store, TokenY: store>(account: &signer, amount: u128) acquires FarmPoolEvent {
        let lp_token = TokenSwapRouter::withdraw_liquidity_token<TokenX, TokenY>(account, amount);
        YieldFarming::stake<
            PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(
            account, TBD::token_address(), lp_token, amount
        );

        // Emit stake event
        let farm_stake_event = borrow_global_mut<FarmPoolEvent>(TBD::token_address());
        Event::emit_event(&mut farm_stake_event.stake_event_handler,
            StakeEvent {
                y_token_code: Token::token_code<TokenX>(),
                x_token_code: Token::token_code<TokenY>(),
                signer: Signer::address_of(account),
                admin: TBD::token_address(),
                amount,
            });
    }

    /// Unstake liquidity Token pair
    public fun unstake<TokenX: store,
                       TokenY: store>(account: &signer) acquires FarmPoolEvent {
        let (liquidity_token, reward_token) = YieldFarming::unstake<
            PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account, TBD::token_address());

        let account_addr = Signer::address_of(account);
        let admin = TBD::token_address();

        TokenSwapRouter::deposit_liquidity_token<TokenX, TokenY>(account_addr, liquidity_token);
        Account::deposit<TBD::TBD>(account_addr, reward_token);

        // Emit unstake event
        let farm_stake_event = borrow_global_mut<FarmPoolEvent>(admin);
        Event::emit_event(&mut farm_stake_event.unstake_event_handler,
            UnstakeEvent {
                y_token_code: Token::token_code<TokenX>(),
                x_token_code: Token::token_code<TokenY>(),
                signer: account_addr,
                admin,
            });
    }

    /// Harvest reward from token pool
    public fun harvest<TokenX: store,
                       TokenY: store>(account: &signer, amount: u128) {
        let token = YieldFarming::harvest<
            PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account, TBD::token_address(), amount);

        let account_addr = Signer::address_of(account);
        if (!Account::is_accept_token<TBD::TBD>(account_addr)) {
            Account::do_accept_token<TBD::TBD>(account);
        };
        Account::deposit<TBD::TBD>(account_addr, token);
    }

    /// Return calculated APY
    public fun lookup_gain<TokenX: store, TokenY: store>(account: &signer): u128 {
        YieldFarming::query_gov_token_amount<
            PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account, TBD::token_address())
    }

    /// Query all stake amount
    public fun query_total_stake<TokenX: store, TokenY: store>(): u128 {
        YieldFarming::query_total_stake<
            PoolTypeLiquidityMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(TBD::token_address())
    }

    /// Query stake amount from user
    public fun query_stake<TokenX: store, TokenY: store>(account: &signer): u128 {
        YieldFarming::query_stake<
            PoolTypeLiquidityMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account)
    }

    /// Query release per second
    public fun query_release_per_second<TokenX: store, TokenY: store>(): u128 acquires FarmParameterModfiyCapability {
        let cap = borrow_global<FarmParameterModfiyCapability<TokenX, TokenY>>(TBD::token_address());
        cap.release_per_seconds
    }

    /// Return calculated APY
    public fun apy<TokenX: store, TokenY: store>(): u128 {
        // TODO(bobong): calculate APY
        0
    }

}
}