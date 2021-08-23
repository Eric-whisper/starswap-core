// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x1 {
module Governance {
    use 0x1::Token;
    use 0x1::Signer;
    use 0x1::Treasury;
    use 0x1::Option;
    use 0x1::Account;
    use 0x1::Timestamp;

    const ERR_GOVER_INIT_REPEATE: u64 = 1000;
    const ERR_GOVER_OBJECT_NONE_EXISTS: u64 = 1001;
    const ERR_GOVER_WITHDRAW_OVERFLOW: u64 = 1002;
    const ERR_GOVER_WEIGHT_DECREASE_OVERLIMIT: u64 = 1003;

    /// The object of governance
    /// GovTokenT meaning token of governance
    /// AssetT meaning asset which has been staked in governance
    struct Governance<GovTokenT> has key, store {
        withdraw_cap: Treasury::WithdrawCapability<GovTokenT>,
        asset_total_weight: u128,
        market_index: u128,
        // By seconds
        last_update_timestamp: u64,
        period_release_amount: u128,
        precision: u128,
    }

    /// Capability to modify parameter such as period and release amount
    struct ParameterModifyCapability has key, store {}

    /// Asset wrapper
    struct AssetWrapper<AssetT> has key {
        asset: AssetT,
        asset_weight: u128,
    }

    /// To store user's asset token
    struct Stake<AssetT> has key, store {
        asset: Option::Option<AssetT>,
        asset_weight: u128,
        last_market_index: u128,
        gain: u128,
    }

    /// Called by token issuer
    /// this will declare a governance pool
    public fun initialize<GovTokenT: store, AssetT: store>(account: &signer,
                                                           treasury: Token::Token<GovTokenT>,
                                                           period_release_amount: u128,
                                                           precision: u128): ParameterModifyCapability {
        assert(!exists_at<GovTokenT, AssetT>(), ERR_GOVER_INIT_REPEATE);

        let withdraw_cap = Treasury::initialize<GovTokenT>(account, treasury);
        move_to(account, Governance<GovTokenT> {
            withdraw_cap,
            asset_total_weight: 0,
            market_index: 0,
            last_update_timestamp: Timestamp::now_seconds(),
            period_release_amount,
            precision,
        });
        ParameterModifyCapability {}
    }

    public fun modify_parameter<GovTokenT: store>(_cap: &ParameterModifyCapability,
                                                  period_release_amount: u128) acquires Governance {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        gov.period_release_amount = period_release_amount;
    }

    /// Borrow from `Stake` object, calling `stake` function to pay back which is `AssetWrapper`
    public fun borrow_assets<AssetT: store>(account: &signer): AssetWrapper<AssetT> acquires Stake {
        let stake = borrow_global_mut<Stake<AssetT>>(Signer::address_of(account));
        let asset = Option::extract(&mut stake.asset);
        AssetWrapper<AssetT> { asset, asset_weight: stake.asset_weight }
    }

    /// Build a new asset from outside
    public fun build_new_asset<AssetT: store>(asset: AssetT, asset_weight: u128): AssetWrapper<AssetT> {
        AssetWrapper<AssetT> { asset, asset_weight }
    }

    /// Call by stake user, staking amount of asset in order to get governance token
    public fun stake<GovTokenT: store, AssetT : store>(account: &signer,
                                                       asset_wrapper: AssetWrapper<AssetT>) acquires Stake, Governance {
        let AssetWrapper<AssetT> { asset, asset_weight } = asset_wrapper;
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);

        if (exists<Stake<AssetT>>(Signer::address_of(account))) {
            let stake = borrow_global_mut<Stake<AssetT>>(Signer::address_of(account));
            // perform settlement before add weight
            settle<GovTokenT, AssetT>(gov, stake);
            stake.asset_weight = stake.asset_weight + asset_weight;
            Option::fill(&mut stake.asset, asset);
        } else {
            move_to(account, Stake<AssetT> {
                asset: Option::some(asset),
                asset_weight,
                last_market_index: gov.market_index,
                gain: 0,
            });
        };
    }

    /// Unstake asset from stake pool
    public fun unstake<GovTokenT: store, AssetT : store>(account: &signer,
                                                         asset_wrapper: AssetWrapper<AssetT>) acquires Stake, Governance {
        let AssetWrapper<AssetT> { asset, asset_weight } = asset_wrapper;

        // Get back asset, and destroy Stake object
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        let stake = borrow_global_mut<Stake<AssetT>>(Signer::address_of(account));

        // Perform settlement
        settle<GovTokenT, AssetT>(gov, stake);

        stake.asset_weight = stake.asset_weight - asset_weight;
        Option::fill(&mut stake.asset, asset);
    }

    /// Withdraw governance token from stake
    public fun withdraw<GovTokenT: store, AssetT : store>(account: &signer,
                                                          amount: u128) acquires Governance, Stake {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        let stake = borrow_global_mut<Stake<AssetT>>(Signer::address_of(account));
        // Perform settlement
        settle(gov, stake);
        assert((stake.gain + amount > 0), ERR_GOVER_WITHDRAW_OVERFLOW);
        // Withdraw goverment token
        let token = Treasury::withdraw_with_capability<GovTokenT>(&mut gov.withdraw_cap, amount);
        Account::deposit<GovTokenT>(Signer::address_of(account), token);
    }

    /// The user can quering all governance amount in any time and scene
    public fun query_gov_token_amount<GovTokenT: store, AssetT: store>(account: &signer): u128 acquires Governance, Stake {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        let stake = borrow_global_mut<Stake<AssetT>>(Signer::address_of(account));
        // Perform settlement
        settle<GovTokenT, AssetT>(gov, stake);

        stake.gain
    }

    /// Performing a settlement based given governance object and stake object.
    public fun settle<GovTokenT: store, AssetT: store>(gov: &mut Governance<GovTokenT>, stake: &mut Stake<AssetT>) {
        let period_gain = calculate_withdraw_amount(gov.market_index, stake.last_market_index, stake.asset_weight);
        stake.last_market_index = gov.market_index;
        stake.gain = stake.gain + period_gain;

        let new_market_index = calculate_market_index(
            gov.market_index, gov.asset_total_weight, gov.last_update_timestamp, gov.period_release_amount);
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
    public fun exists_at<GovTokenT: store, AssetT: store>(): bool {
        let token_issuer = Token::token_address<GovTokenT>();
        exists<Governance<GovTokenT>>(token_issuer)
    }
}
}