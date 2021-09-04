// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0

// TODO: replace the address with admin address
address 0x81144d60492982a45ba93fba47cae988 {
module TokenSwapGov {
    use 0x1::YieldFarming;
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Math;
    use 0x1::Signer;
    use 0x81144d60492982a45ba93fba47cae988::TBD;

    struct PoolTypeLiquidityMint has key, store {}

    struct PoolTypeTeam has key, store {}

    struct PoolTypeInvestor has key, store {}

    struct PoolTypeTechMaintenance has key, store {}

    struct PoolTypeMarket has key, store {}

    struct PoolTypeStockManagement has key, store {}

    struct PoolTypeDaoCrosshain has key, store {}


    struct GovCapability has key, store {
        mint_cap: Token::MintCapability<TBD::TBD>,
        burn_cap: Token::BurnCapability<TBD::TBD>,
    }

    struct GovTreasury<PoolType> has key, store {
        treasury: Token::Token<TBD::TBD>
    }

    struct GovModfiyParamCapability<PoolType, AssetT> has key, store {
        cap: YieldFarming::ParameterModifyCapability<PoolType, AssetT>,
    }

    /// Initial as genesis that will create pool list by Starswap Ecnomic Model list
    public fun genesis_initialize(account: &signer) {
        TBD::assert_genesis_address(account);

        let precision = TBD::precision();
        let scaling_factor = Math::pow(10, (precision as u64));
        let total = 100000000 * scaling_factor;

        // Mint genesis tokens
        let (mint_cap, burn_cap) = TBD::mint(account, total);

        // Freeze token capability which named `mint` and `burn` now
        move_to(account, GovCapability {
            mint_cap,
            burn_cap
        });

        // Release 30% for liquidity token stake
        let lptoken_stake_total = 15000000 * (scaling_factor as u128);
        let lptoken_stake_total_token = Account::withdraw<TBD::TBD>(account, lptoken_stake_total);
        YieldFarming::initialize<PoolTypeLiquidityMint, TBD::TBD>(account, lptoken_stake_total_token);

        // Release 10% for team in 2 years
        let team_total = 10000000 * (scaling_factor as u128);
        move_to(account, GovTreasury<PoolTypeTeam> {
            treasury: Account::withdraw<TBD::TBD>(account, team_total),
        });

        // Release 10% for investor in 2 years
        let investor_total = 10000000 * (scaling_factor as u128);
        move_to(account, GovTreasury<PoolTypeInvestor> {
            treasury: Account::withdraw<TBD::TBD>(account, investor_total),
        });

        // Release technical maintenance 2% value management in 1 year
        let maintenance_total = 2000000 * (scaling_factor as u128);
        move_to(account, GovTreasury<PoolTypeTechMaintenance> {
            treasury: Account::withdraw<TBD::TBD>(account, maintenance_total),
        });

        // Release market management 5% value management in 1 year
        let market_management = 5000000 * (scaling_factor as u128);
        move_to(account, GovTreasury<PoolTypeMarket> {
            treasury: Account::withdraw<TBD::TBD>(account, market_management),
        });

        // Release 1% for stock market value
        let stock_management = 1000000 * (scaling_factor as u128);
        move_to(account, GovTreasury<PoolTypeStockManagement> {
            treasury: Account::withdraw<TBD::TBD>(account, stock_management),
        });

        // Release 42% for DAO and cross chain .
        let dao_and_crosschain_total = 42000000 * (scaling_factor as u128);
        move_to(account, GovTreasury<PoolTypeDaoCrosshain> {
            treasury: Account::withdraw<TBD::TBD>(account, dao_and_crosschain_total),
        });
    }

    /// dispatch to acceptor from governance treasury pool
    public fun dispatch<PoolType: store>(account: &signer, acceptor: address, amount: u128) acquires GovTreasury {
        let treasury = borrow_global_mut<GovTreasury<PoolType>>(Signer::address_of(account));
        let disp_token = Token::withdraw<TBD::TBD>(&mut treasury.treasury, amount);
        Account::deposit<TBD::TBD>(acceptor, disp_token);
    }
}
}