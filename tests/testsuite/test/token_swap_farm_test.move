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
//! block-time: 86410000

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
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapGov;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapFarmScript;
    use admin::TokenMock::{BTC, ETH};

    fun main(signer: signer) {
        TokenSwapGov::genesis_initialize(&signer);
        TokenSwapFarmScript::add_farm_pool_by_router<BTC, ETH>(&signer, 100000000);
    }
}
// check: EXECUTED

//! new-transaction
//! sender: admin
address admin = {{admin}};
script {
    use 0x1::Signer;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapFarmScript;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;
    use admin::TokenMock::{BTC, ETH};

    fun main(signer: signer) {
        let liquidity_amount = TokenSwapRouter::liquidity<BTC, ETH>(Signer::address_of(&signer));
        TokenSwapFarmScript::stake_by_router<BTC, ETH>(&signer, liquidity_amount);

        let stake_amount = TokenSwapFarmScript::query_stake<BTC, ETH>(&signer);
        assert(stake_amount == liquidity_amount, 1003);

        let total_stake_amount = TokenSwapFarmScript::query_total_stake<BTC, ETH>();
        assert(total_stake_amount == liquidity_amount, 1004);
    }
}

//! block-prologue
//! author: genesis
//! block-number: 2
//! block-time: 86420000

//! new-transaction
//! sender: admin
address admin = {{admin}};
script {
    use 0x1::Signer;
    use 0x1::Account;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapFarmScript;
    use 0x81144d60492982a45ba93fba47cae988::TBD;
    use admin::TokenMock::{BTC, ETH};

    fun main(signer: signer) {
        TokenSwapFarmScript::harvest_by_router<BTC, ETH>(&signer, 0);
        let rewards_amount = Account::balance<TBD::TBD>(Signer::address_of(&signer));
        assert(rewards_amount > 0, 1004);
    }
}
// check: EXECUTED

//! block-prologue
//! author: genesis
//! block-number: 3
//! block-time: 86430000

//! new-transaction
//! sender: admin
address admin = {{admin}};
script {
    use 0x1::Signer;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapFarmScript;
    use 0x81144d60492982a45ba93fba47cae988::TokenSwapRouter;
    use admin::TokenMock::{BTC, ETH};

    fun main(signer: signer) {
        TokenSwapFarmScript::unstake_by_router<BTC, ETH>(&signer);
        let liquidity_amount = TokenSwapRouter::liquidity<BTC, ETH>(Signer::address_of(&signer));
        assert(liquidity_amount > 0, 1005);
    }
}
// check: EXECUTED
