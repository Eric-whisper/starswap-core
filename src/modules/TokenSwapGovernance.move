// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGovernance {
    use 0x1::Governance;
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Math;
    use 0x1::Signer;
    use 0x81144d60492982a45ba93fba47cae988::TBD;

    const ERR_USER_NOT_CLAIM : u64 = 40001;

    struct PoolTypeLPTokenMint has key, store {}

    struct PoolTypeTeam has key, store {}

    struct PoolTypeInvestor has key, store {}

    struct PoolTypeTechMaintenance has key, store {}

    struct PoolTypeMarket has key, store {}

    struct LinearReleaseAsset has key, store {
        value: u128,
    }

    struct GovCapability has key, store {
        mint_cap: Token::MintCapability<TBD::TBD>,
        burn_cap: Token::BurnCapability<TBD::TBD>,
    }

    struct GovModfiyParamCapability<PoolType, AssetT> has key, store {
        cap: Governance::ParameterModifyCapability<PoolType, AssetT>,
    }

    /// Initial as genesis that will create pool list by Starswap Ecnomic Model list
    public(script) fun genesis_initialize(account: signer) {
        TBD::assert_genesis_address(&account);

        let precision = TBD::precision();
        let scaling_factor = Math::pow(10, (precision as u64));
        let total = 100000000 * scaling_factor;

        // Mint genesis tokens
        let (mint_cap, burn_cap) = TBD::mint(&account, total);

        // Freeze token capability which named `mint` and `burn` now
        move_to(&account, GovCapability {
            mint_cap,
            burn_cap
        });

        // Release 30% for liquidity token stake
        let lptoken_stake_total = 15000000 * (precision as u128);
        let lptoken_stake_total_token = Account::withdraw<TBD::TBD>(&account, lptoken_stake_total);
        Governance::initialize<PoolTypeLPTokenMint, TBD::TBD>(&account, lptoken_stake_total_token);

        // 10000000/(2*365*24*60*60) = 0.1585489599
        let release_per_seconds_in_2y_10p = 1585489599;
        // 2000000/(1*365*24*60*60) = 0.06341958397
        let relese_per_seconds_in_1y_2p = 63419583;

        // Release 10% for team in 2 years
        let team_total = 10000000 * (precision as u128);
        let team_total_token = Account::withdraw<TBD::TBD>(&account, team_total);
        Governance::initialize<PoolTypeTeam, TBD::TBD>(&account, team_total_token);
        let team_pool_cap = Governance::initialize_asset<
            PoolTypeTeam,
            LinearReleaseAsset>(&account, release_per_seconds_in_2y_10p, 15552000);
        move_to(&account, GovModfiyParamCapability<PoolTypeTeam, LinearReleaseAsset> {
            cap: team_pool_cap,
        });

        // Release 10% for investor in 2 years
        let investor_total = 10000000 * (precision as u128);
        let investor_total_token = Account::withdraw<TBD::TBD>(&account, investor_total);
        Governance::initialize<PoolTypeInvestor, TBD::TBD>(&account, investor_total_token);
        let invest_pool_cap = Governance::initialize_asset<
            PoolTypeInvestor,
            LinearReleaseAsset>(&account, release_per_seconds_in_2y_10p, 0);
        move_to(&account, GovModfiyParamCapability<PoolTypeInvestor, LinearReleaseAsset> {
            cap: invest_pool_cap,
        });

        // Release technical maintenance 2% value management in 1 year
        let maintenance_total = 2000000 * (precision as u128);
        let maintenance_total_token = Account::withdraw<TBD::TBD>(&account, maintenance_total);
        Governance::initialize<PoolTypeTechMaintenance, TBD::TBD>(&account, maintenance_total_token);
        let maintenance_pool_cap = Governance::initialize_asset<
            PoolTypeTechMaintenance,
            LinearReleaseAsset>(&account, relese_per_seconds_in_1y_2p, 0);
        move_to(&account, GovModfiyParamCapability<PoolTypeTechMaintenance, LinearReleaseAsset> {
            cap: maintenance_pool_cap,
        });

        // Release market 5% value management in 1 year
        let market_management = 5000000 * (precision as u128);
        let market_management_token = Account::withdraw<TBD::TBD>(&account, market_management);
        Governance::initialize<PoolTypeMarket, TBD::TBD>(&account, market_management_token);
        let market_pool_cap = Governance::initialize_asset<
            PoolTypeMarket,
            LinearReleaseAsset>(&account, relese_per_seconds_in_1y_2p, 0);
        move_to(&account, GovModfiyParamCapability<PoolTypeMarket, LinearReleaseAsset> {
            cap: market_pool_cap,
        });

        // TODO(BobOng): to dispatch 1. 1% market value 2. 42% DAO and cross chain pool
    }

    /// Called by user, the user claim pool have stake asset
    public(script) fun claim<PoolType: store>(account: signer) {
        Governance::claim<PoolType, TBD::TBD, LinearReleaseAsset>(&account, LinearReleaseAsset { value: 0 });
    }

    /// Called by admin, increase or decrease linear asset value
    public(script) fun admin_add_linear_asset<PoolType: store>(account: signer,
                                                               beneficiary: address,
                                                               amount: u128) acquires GovModfiyParamCapability {
        TBD::assert_genesis_address(&account);
        assert(Governance::exists_stake_at_address<PoolType, TBD::TBD>(beneficiary), ERR_USER_NOT_CLAIM);

        let asset_wrapper = Governance::borrow_asset<PoolType, LinearReleaseAsset>(beneficiary);
        let (asset, asset_weight) = Governance::borrow<PoolType, LinearReleaseAsset>(&mut asset_wrapper);

        asset.value = asset.value + amount;
        Governance::modify(&mut asset_wrapper, asset_weight + amount);

        let cap = borrow_global<GovModfiyParamCapability<PoolType, LinearReleaseAsset>>(Signer::address_of(&account));
        Governance::stake_with_cap<PoolType, TBD::TBD, LinearReleaseAsset>(beneficiary, asset_wrapper, &cap.cap);
    }

    /// Harverst TBD by given pool type, call ed by user
    public(script) fun harvest<LinearPoolType: store>(account: signer) {
        let gain = Governance::query_gov_token_amount<
            LinearPoolType,
            TBD::TBD,
            LinearReleaseAsset>(&account);
        Governance::harvest<LinearPoolType, TBD::TBD, LinearReleaseAsset>(&account, gain);
    }
}
}