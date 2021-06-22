// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

script {
    use 0x1::TokenMock::{BTC, ETH};
    use 0x1::TokenSwap;
    use 0x1::LiquidityToken::LiquidityToken;
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Signer;

    fun register_liquidity(a: signer) {
        let genesis_account = Account::create_genesis_account(Signer::address_of(&a));

        // BTC/ETH = 1:10
        let btc_amount = 1000000;
        let eth_amount = 10000000;

        // Resister and mint BTC
        Token::register_token<BTC>(&genesis_account, 3);
        Account::do_accept_token<BTC>(&genesis_account);
        let stc_token = Token::mint<BTC>(&genesis_account, btc_amount);
        Account::deposit_to_self(&genesis_account, stc_token);

        // Register and mint ETH
        Token::register_token<ETH>(&genesis_account, 3);
        Account::do_accept_token<ETH>(&genesis_account);
        let eth_token = Token::mint<ETH>(&genesis_account, eth_amount);
        Account::deposit_to_self(&genesis_account, eth_token);

        // liquidity mint
        TokenSwap::register_swap_pair<BTC, ETH>(&genesis_account);
        let btc = Account::withdraw<BTC>(&genesis_account, btc_amount);
        let eth = Account::withdraw<ETH>(&genesis_account, eth_amount);
        Account::do_accept_token<LiquidityToken<BTC, ETH>>(&genesis_account);
        let liquidity_token = TokenSwap::mint<BTC, ETH>(btc, eth);
        Account::deposit_to_self(&genesis_account, liquidity_token);

        let (x, y) = TokenSwap::get_reserves<BTC, ETH>();
        assert(x == btc_amount, 111);
        assert(y == eth_amount, 112);

        Account::release_genesis_signer(genesis_account);
    }
}
