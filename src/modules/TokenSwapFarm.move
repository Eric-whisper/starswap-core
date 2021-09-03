// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapFarm {
    use 0x1::YieldFarming;
    use 0x1::Signer;
    use 0x1::Token;
    use 0x1::Account;
    //use 0x1::GovernanceDaoProposal;
    use 0x81144d60492982a45ba93fba47cae988::TBD;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap::LiquidityToken;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGov;

    const ERROR_UNSTAKE_INSUFFICIENT: u64 = 1001;

    struct FarmParameterModfiyCapability<PoolType, AssetT> has key, store {
        cap: YieldFarming::ParameterModifyCapability<PoolType, AssetT>
    }

    /// Initialize Liquidity pair gov pool, only called by token issuer
    public fun add_farm<TokenX: store, TokenY: store>(
        account: &signer,
        release_per_seconds: u128) {
        // Only called by the genesis
        TBD::assert_genesis_address(account);

        // To determine how many amount release in every period
        let cap = YieldFarming::initialize_asset<
            TokenSwapGov::PoolTypeLiquidityMint,
            LiquidityToken<TokenX, TokenY>>(account, release_per_seconds, 0);

        move_to(account, FarmParameterModfiyCapability<
            TokenSwapGov::PoolTypeLiquidityMint,
            LiquidityToken<TokenX, TokenY>> {
            cap
        });
//        // TODO (BobOng): Add to DAO
//        GovernanceDaoProposal::plugin<
//            PoolTypeProposal<TokenX, TokenY, GovTokenT>,
//            GovTokenT>(account, modify_cap);
    }

    /// Stake liquidity Token pair
    public fun stake<TokenX: store, TokenY: store>(account: &signer, amount: u128) {
        let lp_token = TokenSwapRouter::withdraw_liquidity_token<TokenX, TokenY>(account, amount);

        YieldFarming::stake<
            TokenSwapGov::PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(
            account, TBD::token_address(), lp_token, amount
        );
    }

    /// Unstake liquidity Token pair
    public fun unstake<TokenX: store,
                       TokenY: store>(account: &signer) {
        let (liquidity_token, reward_token) = YieldFarming::unstake<
            TokenSwapGov::PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account, TBD::token_address());

        TokenSwapRouter::deposit_liquidity_token<TokenX, TokenY>(Signer::address_of(account), liquidity_token);
        Account::deposit<TBD::TBD>(Signer::address_of(account), reward_token);
    }

    /// Harvest reward from token pool
    public fun harvest<TokenX: store,
                       TokenY: store>(account: &signer, amount: u128) {
        let token = YieldFarming::harvest<
            TokenSwapGov::PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account, TBD::token_address(), amount);
        Account::deposit<TBD::TBD>(Signer::address_of(account), token);
    }

    /// Return calculated APY
    public fun lookup_gain<TokenX: store, TokenY: store>(account: &signer): u128 {
        YieldFarming::query_gov_token_amount<
            TokenSwapGov::PoolTypeLiquidityMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(account, TBD::token_address())
    }

    /// Query all stake amount
    public fun query_total_stake<TokenX: store, TokenY: store>(): u128 {
        YieldFarming::query_total_stake<
            TokenSwapGov::PoolTypeLiquidityMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>
        >(TBD::token_address())
    }

    /// Return calculated APY
    public fun apy<TokenX: store, TokenY: store>(): u128 {
        // TODO(bobong): calculate APY
        0
    }

}
}