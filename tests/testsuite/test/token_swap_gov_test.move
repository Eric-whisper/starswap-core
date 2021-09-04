//! account: alice, 10000000000000 0x1::STC::STC
//! account: bob, 10000000000000 0x1::STC::STC
//! account: admin, 0x81144d60492982a45ba93fba47cae988, 10000000000000 0x1::STC::STC
//! account: liquidier, 10000000000000 0x1::STC::STC
//! account: exchanger

//! sender: admin
address admin = {{admin}};
module admin::TokenMock {
    // mock BTC token
    struct BTC has copy, drop, store {}
    // mock ETH token
    struct ETH has copy, drop, store {}
}

//! block-prologue
//! author: genesis
//! block-number: 1
//! block-time: 86400000

//! new-transaction
//! sender: admin
address admin = {{admin}};
script {
    use 0x1::Account;
    use 0x1::Math;
    use 0x1::Token;
    use admin::TokenMock::{BTC, ETH};
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;

    fun register_token_pair(signer: signer) {
        //token pair register must be swap admin account
        TokenSwapRouter::register_swap_pair<BTC, ETH>(&signer);
        assert(TokenSwapRouter::swap_pair_exists<BTC, ETH>(), 1001);

        let precision: u8 = 9;
        let scaling_factor = Math::pow(10, (precision as u64));

        {
            // Resister and mint BTC
            Token::register_token<BTC>(&signer, precision);
            Account::do_accept_token<BTC>(&signer);
            let mint_token = Token::mint<BTC>(&signer, 100000000 * scaling_factor);
            Account::deposit_to_self(&signer, mint_token);
        };

        {
            // Resister and mint ETH
            Token::register_token<ETH>(&signer, precision);
            Account::do_accept_token<ETH>(&signer);
            let mint_token = Token::mint<ETH>(&signer, 100000000 * scaling_factor);
            Account::deposit_to_self(&signer, mint_token);
        };

        let amount_btc_desired: u128 = 10 * scaling_factor;
        let amount_eth_desired: u128 = 50 * scaling_factor;
        let amount_btc_min: u128 = 1 * scaling_factor;
        let amount_eth_min: u128 = 1 * scaling_factor;
        TokenSwapRouter::add_liquidity<BTC, ETH>(
            &signer, 
            amount_btc_desired,
            amount_eth_desired, 
            amount_btc_min, 
            amount_eth_min);
        let total_liquidity: u128 = TokenSwapRouter::total_liquidity<BTC, ETH>();
        assert(total_liquidity > amount_btc_min, 1002);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: admin
address admin = {{admin}};
script {
    use 0x81144d60492982a45ba93fba47cae988::TBD;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGov;

    fun main(signer: signer) {
        TBD::init(&signer);
        TokenSwapGov::genesis_initialize(&signer);
    }
}
// check: EXECUTED

//! block-prologue
//! author: genesis
//! block-number: 2
//! block-time: 86410000

//! new-transaction
//! sender: alice
address alice = {{alice}};
script {
    use 0x81144d60492982a45ba93fba47cae988::TBD;
    use 0x1::Account;

    fun main(signer: signer) {
        Account::do_accept_token<TBD::TBD>(&signer);
    }
}

//! new-transaction
//! sender: admin
address admin = {{admin}};
address alice = {{alice}};
script {
    use 0x1::Account;
    use 0x81144d60492982a45ba93fba47cae988::TBD;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGov::{
        PoolTypeTeam,
        PoolTypeInvestor,
        PoolTypeTechMaintenance,
        PoolTypeMarket,
        PoolTypeStockManagement,
        PoolTypeDaoCrosshain,
        Self
    };

    fun main(signer: signer) {
        TokenSwapGov::dispatch<PoolTypeTeam>(&signer, @alice, 100000000);
        TokenSwapGov::dispatch<PoolTypeInvestor>(&signer, @alice, 100000000);
        TokenSwapGov::dispatch<PoolTypeTechMaintenance>(&signer, @alice, 100000000);
        TokenSwapGov::dispatch<PoolTypeMarket>(&signer, @alice, 100000000);
        TokenSwapGov::dispatch<PoolTypeStockManagement>(&signer, @alice, 100000000);
        TokenSwapGov::dispatch<PoolTypeDaoCrosshain>(&signer, @alice, 100000000);

        let balance = Account::balance<TBD::TBD>(@alice);
        assert(balance == 600000000, 1003);
    }
}
// check: EXECUTED
