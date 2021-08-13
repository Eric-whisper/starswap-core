// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

address 0x1 {
module Governance {
    use 0x1::Token;
    use 0x1::Block;
    use 0x1::Signer;
    use 0x1::Treasury;
    use 0x1::Option;

    const ERR_GOVER_INIT_REPEATE: u64 = 1000;
    const ERR_GOVER_OBJECT_NONE_EXISTS: u64 = 1001;

    /// Global strategy of governance, used modify by DAO
    struct Strategy<GovTokenT, AssetT> {
        period: u64,
        period_release_amount: u128,

        // extra config to here ...
    }

    /// The object of governance
    /// GovTokenT meaning token of governance
    /// AssetT meaning asset which has been staked in governance
    struct Governance<GovTokenT, AssetT> {
        withdraw_cap: Treasury::WithdrawCapability<GovTokenT>,
        asset_total : u128, // Total locking value of this global governance
        withdraw_total: u128, // Total value of released
    }

    /// To store user's asset token
    struct Stake<AssetT> {
        asset: Token::Token<AssetT>,
        withdraw_amount: u128,
        last_market_index: u128,
    }

    /// Called by token issuer
    /// this will declare a governance pool
    public fun initialize<GovTokenT: store, AssetT: store>(account: &signer,
                                                           treasury: Token::Token<GovTokenT>) {
        assert(!exists_at<GovTokenT, AssetT>(), ERR_GOVER_INIT_REPEATE);

        let withdraw_cap = Treasury::intialize<GovTokenT>(account, treasury);
        move_to(account, Governance<GovTokenT, AssetT> {
            withdraw_cap,
            asset_total: 0,
            withdraw_total: 0,
        });
    }

    /// Call by stake user, staking amount of asset in order to get governance token.
    public fun stake<GovTokenT: store, AssetT : store>(account: &signer, asset: Token::Token<AssetT>)
    acquires Governance, Stake {
        let token_issuer = Token::token_address<GovTokenT>();
        assert(exists<Governance<GovTokenT>>(token_issuer), ERR_GOVER_OBJECT_NONE_EXISTS);

        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        let asset_amount = Token::value_of<AssetT>(asset);
        gov.asset_total = gov.asset_total + asset_amount;

        if (exists<Stake<AssetT>>(Signer::address_of(account))) {
            let stake = borrow_global_mut<Stake<AssetT>>(account);
            Token::deposit(&mut stake.asset, asset);
        } else {
            move_to(account, Stake<AssetT> {
                asset,
                withdraw_amount: 0,
                last_market_index: gov.asset_total
            });
        };
    }

    /// unstake asset from stake pool
    public fun unstake<GovTokenT: store, AssetT : store>(account: &signer)
    acquires Governance, Stake {
        // Get back asset, and destroy Stake object
        let stake = move_from<Stake<AssetT>>(account);
        let asset_amount = Token::value_of(stake.asset);
        Account::deposit(account, stake.asset);

        let token_issuer = Token::token_address<GovTokenT>();
        let gov = borrow_global_mut<Governance<GovTokenT>>(token_issuer);
        gov.asset_total = gov.asset_total - asset_amount;
    }

    /// Withdraw governance token from stake
    public fun withdraw<GovTokenT: store, AssetT : store>(account: &signer) {
        // TODO(BobOng): TO Calculate withdraw amount
    }

    /// Check the Governance of TokenT is exists.
    public fun exists_at<GovTokenT: store + key + drop
                         AssetT : store>(): bool {
        let token_issuer = Token::token_address<GovTokenT>();
        exists<Governance<GovTokenT>>(token_issuer)
    }
}
    //      // 管理员检查
//      TokenSwapGovConfig::assert_admin();
//      assert(!exists<FrozenPool>(Signer::address_of(account))), 10002);
//      // 初始化代币并mint对应的代币额度
//      GOV::init(account, amount);
//
//        // 将质押部分的代币取出存入到当前合约
//      let frozen_amount = amount * 18044 / 1000000;
//      let reserve = Account::withdraw<GOV::GOV>(account);
//      move_to(account, FrozenPool { reserve });
//    }

    /// 普通用户质押
//    public fun stake<X, Y>(account: &signer, amount: u128) {
//    // 将当前liquidity质押在当前合约下
//    let cur_block_num = Block::get_current_block_number();
//    let liquidity_token = TokenSwap::withdraw_liquidity_token<X, Y>(signer, amount);
//    move_to(account, Stake<X, Y>{
//        liquidity_token,
//        stake_block_num : cur_block_num,
//        cur_block_num : cur_block_num,
//        0,
//    });
//  }

    /// 退回质押
//  public fun unstake<X, Y>(account: &signer, amount: u128) {
//      let stake = borrow_global_mut<Stake<X, Y>>(account);
//      let gov_amount = 0; // TODO 计算治理币对应的LPLiquidityToken额度
//      let gov_token = Account::withdraw<GOV::GOV>(&account, gov_amount);
//
//      // 治理币还回给冻结池
//      let frozen_pool = borrow_global_mut<FrozenPool>(TokenSwapGovConfig::admin_address());
//      Token::deposit<GOV::GOV>(frozen_pool.reserve, gov_token);
//
//      // 将 LP token 从权证中还回到Swap池中
//      TokenSwap::pay_back_liquidity_token<X, Y>(account, stake.liquidity_token, amount);
//    }

    /// Get rewards with stake
//  public fun withdraw_rewards<X: store, Y: store>(account: &signer) {
//    let stake = borrow_global_mut<Stake<X, Y>>(account);
//    let curr_block_num = Block::get_current_block_number();
//    assert(current_block_num > stake.last_block_num, 10000);
//
//    // 按照配置取对应额度的治理币下发给用户
//    let diff_block_num = curr_block_num - stake.last_block_num;
//    let block_amount = TokenSwapGovConfig::get_block_amount<X, Y>();
//    let frozen_pool = borrow_global_mut<FrozenPool>(TokenSwapGovConfig::admin_address());
//    let gov = Token::withdraw(&mut frozen_pool.reserve, diff_block_num * block_amount);
//    Account::deposit<GOV::GOV>(Signer::address_of(account), gov);
//
//    // 更新权证
//    stake.last_block_num = curr_block_num;
//  }
// }