// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x1 {
module Governance {
    use 0x1::Token;
    use 0x1::Block;
    use 0x1::Signer;
    use 0x1::Treasury;
    use 0x1::Option;
    use 0x1::TimeStamp;

    const ERR_GOVER_INIT_REPEATE: u64 = 1000;
    const ERR_GOVER_OBJECT_NONE_EXISTS: u64 = 1001;
    const ERR_GOVER_WITHDRAW_OVERFLOW: u64 = 1002;

    /// The object of governance
    /// GovTokenT meaning token of governance
    /// AssetT meaning asset which has been staked in governance
    struct Governance<GovTokenT, AssetT> has key, store{
        withdraw_cap: Treasury::WithdrawCapability<GovTokenT>,
        asset_total: u128,
        market_index: u128,
        // Total locking value of this global governance
        withdraw_total: u128,
        // Global strategy of governance, used modify by DAO, by seconds
        period: u64,
        // By seconds
        last_update_timestamp: u64,
        period_release_amount: u128,
        precision: u128,
    }

    /// Capability to modify parameter such as period and release amount
    struct ParameterModifyCapability<GovTokenT> has key, store {}

    /// Asset wrapper
    struct AssetWrapper<AssetT> has key {
        asset : AssetT,
    }

    /// To store user's asset token
    struct Stake<AssetT> {
        asset: Option::Option<AssetT>,
        asset_weight: u128,
        withdraw_amount: u128,
        last_market_index: u128,
    }

    /// Called by token issuer
    /// this will declare a governance pool
    public fun initialize<GovTokenT: store, AssetT: store>(account: &signer,
                                                           treasury: Token::Token<GovTokenT>,
                                                           period: u64,
                                                           period_release_amount: u128,
                                                           precision: u128) : ParameterModifyCapability {
        assert(!exists_at<GovTokenT, AssetT>(), ERR_GOVER_INIT_REPEATE);

        let withdraw_cap = Treasury::intialize<GovTokenT>(account, treasury);
        move_to(account, Governance<GovTokenT, AssetT> {
            withdraw_cap,
            asset_total: 0,
            withdraw_total: 0,
            market_index: 0,
            period,
            last_update_timestamp: TimeStamp::now_seconds(),
            period_release_amount,
            precision,

        });
        ParameterModifyCapability {}
    }

    spec initialize {
        aborts_if !exists_at<GovTokenT, AssetT>();
    }

    public fun modify_parameter<GovTokenT>(_cap: &ParameterModifyCapability,
                                           period: u64,
                                           period_release_amount: u128) acquires Governance {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        gov.period = period;
        gov.period_release_amount = period_release_amount;
    }

    /// Borrow from `Stake` object, calling `stake` function to pay back which is `AssetWrapper`
    public fun borrow_assets<AssetT: store>(account: &signer,
                                            asset_weight: u128): AssetWrapper<AssetT> acquires Stake<AssetT> {
        let stake = borrow_global_mut<Stake<AssetT>>(account);
        let asset = Option::extract(stake.asset);
        AssetWrapper<AssetT> { asset: Option::extract(&mut stake.asset) }
    }

    /// Call by stake user, staking amount of asset in order to get governance token
    public fun stake<GovTokenT: store, AssetT : store>(account: &signer,
                                                       asset_wrapper: AssetWrapper<AssetT>,
                                                       asset_weight: u128) acquires Governance, Stake {

        let token_issuer = Token::token_address<GovTokenT>();
        assert(exists<Governance<GovTokenT>>(token_issuer), ERR_GOVER_OBJECT_NONE_EXISTS);

        let AssetWrapper<AssetT> { asset : asset } = asset_wrapper;

        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        gov.asset_total = gov.asset_total + asset_weight;

        // calculate market index
        let time_period = (Timestamp::now_seconds() - gov.last_update_timestamp) / gov.period;
        gov.market_index = gov.market_index + (gov.period_release_amount * (gov.period) / gov.asset_total);

        if (exists<Stake<AssetT>>(Signer::address_of(account))) {
            let stake = borrow_global_mut<Stake<AssetT>>(account);
            stake.last_market_index = gov.market_index;
            stake.asset_weight = asset_weight;
            Option::fill(&mut stake.asset, asset);
        } else {
            move_to(account, Stake<AssetT> {
                asset: Option::some(asset_wrapper.asset),
                asset_weight,
                withdraw_amount: 0,
                last_market_index: gov.market_index,
            });
        };
    }

    /// unstake asset from stake pool
    public fun unstake<GovTokenT: store, AssetT : store>(account: &signer,
                                                         asset_wrapper: AssetWrapper<AssetT>,
                                                         asset_weight: u128) acquires Governance, Stake {
        // Get back asset, and destroy Stake object
        let stake = move_from<Stake<AssetT>>(account);
        let asset_amount = Token::value_of(stake.asset);
        Account::deposit(account, stake.asset);

        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        gov.asset_total = gov.asset_total - asset_amount;
    }

    /// Withdraw governance token from stake
    public fun withdraw<GovTokenT: store, AssetT : store>(account: &signer,
                                                          amount: u128) acquires Governance, Stake {
        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        let stake = borrow_global_mut<Stake<AssetT>>(account);

        // calculate withdraw amount
        let total_amount = stake.asset_weight * (stake.last_market_index - gov.market_index);
        assert(amount + stake.withdraw_amount <= total_amount, ERR_GOVER_WITHDRAW_OVERFLOW);

        Treasury::withdraw_with_capability(gov.withdraw_cap, amount);

        gov.withdraw_total = gov.withdraw_total + amount;
        stake.withdraw_amount = stake.withdraw_amount + amount;
    }

    /// Check the Governance of TokenT is exists.
    public fun exists_at<GovTokenT: store + key + drop
                         AssetT : store>(): bool {
        let token_issuer = Token::token_address<GovTokenT>();
        exists<Governance<GovTokenT>>(token_issuer)
    }
}