// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapFarm {
    use 0x1::Governance;
    use 0x1::Signer;
    use 0x1::Token;
    //use 0x1::GovernanceDaoProposal;
    use 0x81144d60492982a45ba93fba47cae988::TBD;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwap::LiquidityToken;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGovernance;

    const ERROR_UNSTAKE_INSUFFICIENT: u64 = 1001;

    struct FarmParameterModfiyCapability<PoolType, AssetT> has key, store {
        cap: Governance::ParameterModifyCapability<PoolType, AssetT>
    }

    /// Initialize Liquidity pair gov pool, only called by token issuer
    public fun add_farm<TokenX: store, TokenY: store>(
        account: &signer,
        release_per_seconds: u128) {
        // Only called by the genesis
        TBD::assert_genesis_address(account);

        // To determine how many amount release in every period
        let cap = Governance::initialize_asset<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            LiquidityToken<TokenX, TokenY>>(account, release_per_seconds, 0);

        move_to(account, FarmParameterModfiyCapability<
            TokenSwapGovernance::PoolTypeLPTokenMint,
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

        // If not claim, then claiming it
        if (!Governance::exists_stake_at_address<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(Signer::address_of(account))) {
            let lp_token = TokenSwapRouter::withdraw_liquidity_token<TokenX, TokenY>(account, 0);

            Governance::claim<
                TokenSwapGovernance::PoolTypeLPTokenMint,
                TBD::TBD,
                Token::Token<LiquidityToken<TokenX, TokenY>>>(account, lp_token);
        };

        let lp_token = TokenSwapRouter::withdraw_liquidity_token<TokenX, TokenY>(account, amount);

        let asset_wrapper = Governance::borrow_asset<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(Signer::address_of(account));

        let (asset, asset_weight) = Governance::borrow<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(&mut asset_wrapper);

        Token::deposit<LiquidityToken<TokenX, TokenY>>(asset, lp_token);
        Governance::modify(&mut asset_wrapper, asset_weight + amount);

        Governance::stake<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(account, asset_wrapper);
    }

    /// Unstake liquidity Token pair
    public fun unstake<TokenX: store,
                       TokenY: store>(
        account: &signer, amount: u128) {
        let asset_wrapper = Governance::borrow_asset<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(Signer::address_of(account));

        let (asset, asset_weight) = Governance::borrow<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(&mut asset_wrapper);

        assert(asset_weight >= amount, ERROR_UNSTAKE_INSUFFICIENT);

        TokenSwapRouter::deposit_liquidity_token<TokenX, TokenY>(
            Signer::address_of(account),
            Token::withdraw<LiquidityToken<TokenX, TokenY>>(asset, amount));

        Governance::modify(&mut asset_wrapper, asset_weight - amount);

        Governance::stake<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(account, asset_wrapper);
    }

    /// Harvest reward from token pool
    public fun harvest<TokenX: store,
                       TokenY: store>(
        account: &signer, amount: u128) {
        Governance::harvest<
            TokenSwapGovernance::PoolTypeLPTokenMint,
            TBD::TBD,
            Token::Token<LiquidityToken<TokenX, TokenY>>>(account, amount);
    }

    /// Return calculated APY
    public fun apy<TokenX: store, TokenY: store>(): u128 {
        // TODO(bobong): calculate APY
        0
    }
}
}