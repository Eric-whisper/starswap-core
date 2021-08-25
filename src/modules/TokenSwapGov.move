// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGov {
    use 0x1::Governance;
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::Token;
    // use 0x1::GovernanceDaoProposal;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap::LiquidityToken;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;

    const ERROR_UNSTAKE_INSUFFICIENT: u64 = 1001;

    struct PoolType<TokenX, TokenY> has store {}

    /// Initialize Liquidity pair gov pool, only called by token issuer
    public fun initialize<X: store,
                          Y: store,
                          GovTokenT: store>(
        account: &signer,
        amount: u128,
        _precision: u128) {
        let gov_token_freeze = Account::withdraw<GovTokenT>(account, amount);
        Governance::initialize<PoolType<X, Y>, GovTokenT>(account, gov_token_freeze);

        // To determine how many amount release in every period
        //        let modify_cap = Governance::initialize_asset<PoolType<X, Y>, GovTokenT>(account, 100);
        //
        //        // Add to DAO
        //        GovernanceDaoProposal::plugin<
        //            PoolType<X, Y>,
        //            GovTokenT,
        //            Token::Token<LiquidityToken<X, Y>>>(
        //            account, modify_cap);
    }

    /// Stake liquidity Token pair
    public fun stake<X: store, Y: store, GovTokenT: store>(account: &signer, amount: u128) {
        let liquidity_token = TokenSwapRouter::withdraw_liquidity_token<X, Y>(account, amount);

        if (Governance::exists_at<PoolType<X, Y>, GovTokenT>()) {
            let asset_wrapper = Governance::borrow_asset<PoolType<X, Y>, Token::Token<LiquidityToken<X, Y>>>(account);
            let (asset, asset_weight) = Governance::borrow<PoolType<X, Y>, Token::Token<LiquidityToken<X, Y>>>(&mut asset_wrapper);

            Token::deposit<LiquidityToken<X, Y>>(asset, liquidity_token);
            Governance::modify(&mut asset_wrapper, asset_weight + amount);

            Governance::stake<PoolType<X, Y>, GovTokenT, Token::Token<LiquidityToken<X, Y>>>(account, asset_wrapper);
        } else {
            let asset_wrapper = Governance::build_new_asset<PoolType<X, Y>, Token::Token<LiquidityToken<X, Y>>>(liquidity_token, amount);
            Governance::stake<PoolType<X, Y>, GovTokenT, Token::Token<LiquidityToken<X, Y>>>(account, asset_wrapper);
        };
    }

    /// Unstake liquidity Token pair
    public fun unstake<X: store,
                       Y: store,
                       GovTokenT: store
    >(account: &signer, amount: u128) {
        let asset_wrapper = Governance::borrow_asset<PoolType<X, Y>, Token::Token<LiquidityToken<X, Y>>>(account);
        let (asset, asset_weight) = Governance::borrow<PoolType<X, Y>, Token::Token<LiquidityToken<X, Y>>>(&mut asset_wrapper);

        assert(asset_weight >= amount, ERROR_UNSTAKE_INSUFFICIENT);

        TokenSwapRouter::deposit_liquidity_token<X, Y>(
            Signer::address_of(account),
            Token::withdraw<LiquidityToken<X, Y>>(asset, amount));

        Governance::unstake<PoolType<X, Y>, GovTokenT, Token::Token<LiquidityToken<X, Y>>>(account, asset_wrapper);
    }

    /// Get award from token pool
    public fun withdraw<X: store, Y: store, GovTokenT: store>(account: &signer, amount: u128) {
        Governance::withdraw<PoolType<X, Y>, GovTokenT, Token::Token<LiquidityToken<X, Y>>>(account, amount);
    }

    /// Return calculated APY
    public fun apy<X: store, Y: store>(): u128 {
        // TODO(bobong): calculate APY
        0
    }
}
}