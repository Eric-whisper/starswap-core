// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED


script {
    use 0x569ab535990a17ac9afd1bc57faec683::TokenMock::{BTC, ETH};
    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwap;
    use 0x569ab535990a17ac9afd1bc57faec683::TokenSwapRouter;
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Signer;

    fun add_liquidity(account: signer) {
        let genesis_account = Account::create_genesis_account(Signer::address_of(&account));

        let presision: u128 = 100000000;

        let btc_amount: u128 = 1000 * presision;
        let eth_amount: u128 = 1000 * presision;

        // 1. Resister and mint BTC
        Token::register_token<BTC>(&genesis_account, 3);
        Account::do_accept_token<BTC>(&genesis_account);
        let stc_token = Token::mint<BTC>(&genesis_account, btc_amount);
        Account::deposit_to_self(&genesis_account, stc_token);

        // 2. Register and mint ETH
        Token::register_token<ETH>(&genesis_account, 3);
        Account::do_accept_token<ETH>(&genesis_account);
        let eth_token = Token::mint<ETH>(&genesis_account, eth_amount);
        Account::deposit_to_self(&genesis_account, eth_token);

        // 3. Register swap pair first
        TokenSwap::register_swap_pair<BTC, ETH>(&genesis_account);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Add liquidity, BTC/ETH = 1:10
        let amount_btc_desired: u128 = 10 * presision;
        let amount_eth_desired: u128 = 100 * presision;
        let amount_btc_min: u128 = 1 * presision;
        let amount_eth_min: u128 = 1 * presision;
        TokenSwapRouter::add_liquidity<BTC, ETH>(&genesis_account,
            amount_btc_desired, amount_eth_desired, amount_btc_min, amount_eth_min);
        let total_liquidity: u128 = TokenSwapRouter::total_liquidity<BTC, ETH>();
        assert(total_liquidity > amount_btc_min, 10000);
        // Balance verify
        assert(Account::balance<BTC>(Signer::address_of(&genesis_account)) ==
                (btc_amount - amount_btc_desired), 10001);
        assert(Account::balance<ETH>(Signer::address_of(&genesis_account)) ==
                (eth_amount - amount_eth_desired), 10002);

        ////////////////////////////////////////////////////////////////////////////////////////////
        // Swap token pair, put A BTC, got 10 eth
        let pledge_btc_amount: u128 = 1 * presision;
        let pledge_eth_amount: u128 = 10 * presision;
        TokenSwapRouter::swap_exact_token_for_token<BTC, ETH>(
            &genesis_account, pledge_btc_amount, pledge_btc_amount);
        assert(Account::balance<BTC>(Signer::address_of(&genesis_account)) ==
                (btc_amount - amount_btc_desired - pledge_btc_amount), 10004);
        // TODO: To verify why swap out less than ratio swap out
        assert(Account::balance<ETH>(Signer::address_of(&genesis_account)) <=
                (eth_amount - amount_eth_desired + pledge_eth_amount), 10005);

        Account::release_genesis_signer(genesis_account);
    }
}