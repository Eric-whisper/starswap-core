// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGov {
    use 0x1::Governance;
    use 0x1::GovernanceParamDao;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap;

    /// Initialize Liquidity pair gov pool, only called by token issuer
    public fun initialize<X: store, Y: store, GovTokenType: store>(account :&signer,
                                                                   amount: u128,
                                                                   precision: u128) {
        let gov_token_freeze = Account::withdraw(account, amount);
        let modify_cap = Governance::initialize<GovTokenType, TokenSwap::LiquidityToken<X,Y>>(
            account, gov_token_freeze, 60, 100, precision);

        // Add to DAO
        GovernanceDaoProposal::plugin<GovTokenType>(signer, modify_cap);
    }

    /// Stake liquidity Token pair
    public fun stake_liquidity<X: store, Y: store, GovTokenType: store>(account :&signer, amount: u128) {
        let lptoken = TokenSwap::withdraw_lptoken<X, Y>(amount);
        if (Governance::exists_at<GovTokenType, TokenSwap::LiquidityToken<X, Y>>()) {
            let asset_wrapper = Governance::borrow_assets<
                GovTokenType, TokenSwap::LiquidityToken<X, Y>>(account, lptoken);
            Token::deposit<TokenSwap::LiquidityToken<X, Y>>(&mut asset_wrapper.asset, lptoken);
            Governance::stake(account, asset_wrapper);
        } else {
            let asset_wrapper = Governance::build_new_asset<>(lptoken, amount);
            Governance::stake(account, asset_wrapper);
        };
    }

    /// Unstake liquidity Token pair
    public fun unstake_liquidity<X: store, Y: store>(account :&signer, amount: u128) {
        let asset_wrapper = Governance::borrow_assets<GovTokenType>(account, lptoken);
        TokenSwap::deposit<X, Y>(account, asset_wrapper.asset);
        Governance::unstake(account, asset_wrapper);
    }

    /// Get award from token pool
    public fun receive_award<X: store, Y: store>(account :&signer, amount: u128) {

    }

}
}