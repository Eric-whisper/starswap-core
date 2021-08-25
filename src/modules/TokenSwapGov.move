// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGov {
    use 0x1::Governance;
    use 0x1::Account;
    use 0x1::Signer;
    use 0x1::Token;
    use 0x1::GovernanceDaoProposal;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap::LiquidityToken;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;

    const ERROR_UNSTAKE_INSUFFICIENT: u64 = 1001;

    struct PoolType<TokenX, TokenY> has store {}

    struct PoolTypeProposal<TokenX, TokenY, GovTokenT> has copy, drop, store {}

    /// Initialize Liquidity pair gov pool, only called by token issuer
    public fun initialize<TokenX: store + copy + drop,
                          TokenY: store + copy + drop,
                          GovTokenT: store + copy + drop>(
        account: &signer,
        amount: u128,
        _precision: u128) {
        let gov_token_freeze = Account::withdraw<GovTokenT>(account, amount);
        Governance::initialize<PoolType<TokenX, TokenY>, GovTokenT>(account, gov_token_freeze);

        // To determine how many amount release in every period
        let modify_cap = Governance::initialize_asset<
            PoolType<TokenX, TokenY>,
            LiquidityToken<TokenX, TokenY>>(account, 100);

        // Add to DAO
        GovernanceDaoProposal::plugin<
            PoolTypeProposal<TokenX, TokenY, GovTokenT>,
            GovTokenT>(account, modify_cap);
    }

    /// Stake liquidity Token pair
    public fun stake<TokenX: store,
                     TokenY: store,
                     GovTokenT: store>(
        account: &signer, amount: u128) {
        let liquidity_token = TokenSwapRouter::withdraw_liquidity_token<TokenX, TokenY>(account, amount);

        if (Governance::exists_at<PoolType<TokenX, TokenY>, GovTokenT>()) {
            let asset_wrapper = Governance::borrow_asset<
                PoolType<TokenX, TokenY>,
                Token::Token<LiquidityToken<TokenX, TokenY>>>(account);

            let (asset, asset_weight) = Governance::borrow<
                PoolType<TokenX, TokenY>,
                Token::Token<LiquidityToken<TokenX, TokenY>>>(&mut asset_wrapper);

            Token::deposit<LiquidityToken<TokenX, TokenY>>(asset, liquidity_token);
            Governance::modify(&mut asset_wrapper, asset_weight + amount);

            Governance::stake<
                PoolType<TokenX, TokenY>,
                GovTokenT,
                Token::Token<LiquidityToken<TokenX, TokenY>>>(account, asset_wrapper);
        } else {
            let asset_wrapper = Governance::build_new_asset<
                PoolType<TokenX, TokenY>,
                Token::Token<LiquidityToken<TokenX, TokenY>>>(liquidity_token, amount);

            Governance::stake<
                PoolType<TokenX, TokenY>,
                GovTokenT,
                Token::Token<LiquidityToken<TokenX, TokenY>>>(account, asset_wrapper);
        };
    }

    /// Unstake liquidity Token pair
    public fun unstake<TokenX: store,
                       TokenY: store,
                       GovTokenT: store>(
        account: &signer, amount: u128) {
        let asset_wrapper = Governance::borrow_asset<
            PoolType<TokenX, TokenY>,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(account);

        let (asset, asset_weight) = Governance::borrow<
            PoolType<TokenX, TokenY>,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(&mut asset_wrapper);

        assert(asset_weight >= amount, ERROR_UNSTAKE_INSUFFICIENT);

        TokenSwapRouter::deposit_liquidity_token<TokenX, TokenY>(
            Signer::address_of(account),
            Token::withdraw<LiquidityToken<TokenX, TokenY>>(asset, amount));

        Governance::modify(&mut asset_wrapper, asset_weight - amount);

        Governance::unstake<
            PoolType<TokenX, TokenY>,
            GovTokenT,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(account, asset_wrapper);
    }

    /// Get award from token pool
    public fun withdraw<TokenX: store,
                        TokenY: store,
                        GovTokenT: store>(
        account: &signer, amount: u128) {
        Governance::withdraw<
            PoolType<TokenX, TokenY>,
            GovTokenT,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(account, amount);
    }

    /// Return calculated APY
    public fun apy<TokenX: store, TokenY: store>(): u128 {
        // TODO(bobong): calculate APY
        0
    }
}
}