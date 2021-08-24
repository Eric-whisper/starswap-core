// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x1 {
module Governance {
    use 0x1::Token;
    use 0x1::Signer;
    use 0x1::Option;
    use 0x1::Account;
    use 0x1::Timestamp;
    use 0x1::GovernanceTreasury;

    const ERR_GOVER_INIT_REPEATE: u64 = 1000;
    const ERR_GOVER_OBJECT_NONE_EXISTS: u64 = 1001;
    const ERR_GOVER_WITHDRAW_OVERFLOW: u64 = 1002;
    const ERR_GOVER_WEIGHT_DECREASE_OVERLIMIT: u64 = 1003;

    /// The object of governance
    /// GovTokenT meaning token of governance
    /// AssetT meaning asset which has been staked in governance
    struct Governance<PoolType, GovTokenT> has key, store {
        withdraw_cap: GovernanceTreasury::WithdrawCapability<PoolType, GovTokenT>,
    }

    struct GovernanceAsset<PoolType, AssetT> has key, store {
        asset_total_weight: u128,
        market_index: u128,
        // By seconds
        last_update_timestamp: u64,
    }

    /// Capability to modify parameter such as period and release amount
    struct ParameterModifyCapability has key, store {}

    /// Asset wrapper
    struct AssetWrapper<PoolType, AssetT> has key {
        asset: AssetT,
        asset_weight: u128,
    }

    /// To store user's asset token
    struct Stake<PoolType, AssetT> has key, store {
        asset: Option::Option<AssetT>,
        asset_weight: u128,
        last_market_index: u128,
        gain: u128,
    }

    /// Called by token issuer
    /// this will declare a governance pool
    public fun initialize<
        PoolType: store,
        GovTokenT: store>(account: &signer,
                          treasury: Token::Token<GovTokenT>) {
        assert(!exists_at<PoolType, GovTokenT>(), ERR_GOVER_INIT_REPEATE);

        let withdraw_cap = GovernanceTreasury::initialize<PoolType, GovTokenT>(account, treasury);
        move_to(account, Governance<PoolType, GovTokenT> {
            withdraw_cap,
        });
    }

    // Initialize asset pools
    public fun initialize_asset<
        PoolType: store,
        AssetT: store>(account: &signer): ParameterModifyCapability {
        assert(!exists_asset_at<PoolType, AssetT>(), ERR_GOVER_INIT_REPEATE);

        move_to(account, GovernanceAsset<PoolType, AssetT> {
            asset_total_weight: 0,
            market_index: 0,
            last_update_timestamp: Timestamp::now_seconds(),
        });
        ParameterModifyCapability {}
    }

    public fun modify_parameter<PoolType: store,
                                AssetT: store>(
        _cap: &ParameterModifyCapability,
        period_release_amount: u128) acquires GovernanceAsset {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov_asset = borrow_global_mut<GovernanceAsset<PoolType, AssetT>>(token_issuer);
        gov_asset.period_release_amount = period_release_amount;

        // Recalculate market index
        let new_market_index = calculate_market_index(
            gov_asset.market_index,
            gov_asset.asset_total_weight,
            gov_asset.last_update_timestamp,
            gov_asset.period_release_amount);
        gov_asset.market_index = new_market_index;
        gov_asset.last_update_timestamp = Timestamp::now_seconds();
    }

    /// Borrow from `Stake` object, calling `stake` function to pay back which is `AssetWrapper`
    public fun borrow_assets<PoolType: store,
                             AssetT: store>(
        account: &signer): AssetWrapper<PoolType, AssetT> acquires Stake {
        let stake = borrow_global_mut<Stake<PoolType, AssetT>>(Signer::address_of(account));
        let asset = Option::extract(&mut stake.asset);
        AssetWrapper<PoolType, AssetT> {
            asset,
            asset_weight: stake.asset_weight
        }
    }

    /// Build a new asset from outside
    public fun build_new_asset<PoolType: store,
                               AssetT: store>(asset: AssetT, asset_weight: u128)
    : AssetWrapper<PoolType, AssetT> {
        AssetWrapper<PoolType, AssetT> { asset, asset_weight }
    }

    /// Call by stake user, staking amount of asset in order to get governance token
    public fun stake<PoolType: store,
                     GovTokenT: store,
                     AssetT : store>(
        account: &signer,
        asset_wrapper: AssetWrapper<PoolType, AssetT>) acquires Stake, GovernanceAsset {
        let AssetWrapper<PoolType, AssetT> { asset, asset_weight } = asset_wrapper;
        let token_issuer = Token::token_address<GovTokenT>();
        let gov_asset = borrow_global_mut<GovernanceAsset<PoolType, GovTokenT>>(token_issuer);

        if (exists<Stake<PoolType, AssetT>>(Signer::address_of(account))) {
            let stake = borrow_global_mut<Stake<PoolType, AssetT>>(Signer::address_of(account));
            // perform settlement before add weight
            settle<PoolType, GovTokenT, AssetT>(gov_asset, stake);
            stake.asset_weight = stake.asset_weight + asset_weight;
            Option::fill(&mut stake.asset, asset);
        } else {
            move_to(account, Stake<PoolType, AssetT> {
                asset: Option::some(asset),
                asset_weight,
                last_market_index: gov_asset.market_index,
                gain: 0,
            });
        };
    }

    /// Unstake asset from stake pool
    public fun unstake<PoolType: store,
                       GovTokenT: store,
                       AssetT : store>(
        account: &signer,
        asset_wrapper: AssetWrapper<PoolType, AssetT>) acquires Stake, GovernanceAsset {
        let AssetWrapper<PoolType, AssetT> { asset, asset_weight } = asset_wrapper;

        // Get back asset, and destroy Stake object
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<GovernanceAsset<PoolType, GovTokenT>>(token_issuer);
        let stake = borrow_global_mut<Stake<PoolType, AssetT>>(Signer::address_of(account));

        // Perform settlement
        settle<PoolType, GovTokenT, AssetT>(gov, stake);

        stake.asset_weight = stake.asset_weight - asset_weight;
        Option::fill(&mut stake.asset, asset);
    }

    /// Withdraw governance token from stake
    public fun withdraw<PoolType: store,
                        GovTokenT: store,
                        AssetT : store>(account: &signer,
                                        amount: u128) acquires GovernanceAsset, Stake {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<GovernanceAsset<PoolType, GovTokenT>>(token_issuer);
        let stake = borrow_global_mut<Stake<PoolType, AssetT>>(Signer::address_of(account));
        // Perform settlement
        settle(gov, stake);

        assert((stake.gain + amount > 0), ERR_GOVER_WITHDRAW_OVERFLOW);

        // Withdraw goverment token
        let token = GovernanceTreasury::withdraw_with_capability<PoolType, GovTokenT>(&mut gov.withdraw_cap, amount);
        Account::deposit<GovTokenT>(Signer::address_of(account), token);
    }

    /// The user can quering all governance amount in any time and scene
    public fun query_gov_token_amount<PoolType: store,
                                      GovTokenT: store,
                                      AssetT : store>(account: &signer): u128 acquires GovernanceAsset, Stake {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<GovernanceAsset<PoolType, GovTokenT>>(token_issuer);
        let stake = borrow_global_mut<Stake<PoolType, AssetT>>(Signer::address_of(account));
        // Perform settlement
        settle<PoolType, GovTokenT, AssetT>(gov, stake);

        stake.gain
    }

    /// Performing a settlement based given governance object and stake object.
    public fun settle<PoolType: store,
                      GovTokenT: store,
                      AssetT: store>(gov: &mut GovernanceAsset<PoolType, AssetT>,
                                     stake: &mut Stake<PoolType, AssetT>) {
        let period_gain = calculate_withdraw_amount(gov.market_index, stake.last_market_index, stake.asset_weight);
        stake.last_market_index = gov.market_index;
        stake.gain = stake.gain + period_gain;

        let new_market_index = calculate_market_index(
            gov.market_index,
            gov.asset_total_weight,
            gov.last_update_timestamp,
            gov.period_release_amount);
        gov.market_index = new_market_index;
        gov.last_update_timestamp = Timestamp::now_seconds();
    }

    /// There is calculating from market index and global parameters,
    /// such as inline function in C language.
    fun calculate_market_index(market_index: u128,
                               asset_total_weight: u128,
                               last_update_timestamp: u64,
                               period_release_amount: u128): u128 {
        let now = Timestamp::now_seconds();
        let time_period = now - last_update_timestamp;
        let new_market_index = market_index + (period_release_amount * (time_period as u128)) / asset_total_weight;
        new_market_index
    }

    /// This function will return a gain index
    fun calculate_withdraw_amount(market_index: u128,
                                  last_market_index: u128,
                                  asset_weight: u128): u128 {
        asset_weight * (market_index - last_market_index)
    }

    /// Check the Governance of TokenT is exists.
    public fun exists_at<PoolType: store, GovTokenT: store>(): bool {
        let token_issuer = Token::token_address<GovTokenT>();
        exists<Governance<PoolType, GovTokenT>>(token_issuer)
    }

    /// Check the Governance of AsssetT is exists.
    public fun exists_asset_at<PoolType: store, AssetT: store>(): bool {
        let token_issuer = Token::token_address<AssetT>();
        exists<GovernanceAsset<PoolType, AssetT>>(token_issuer)
    }
}
}