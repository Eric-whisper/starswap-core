// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED


script {
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Signer;
    use 0x1::MyToken::{MyToken, Self};

    fun main(a: signer) {
        let new_account = Account::create_genesis_account(Signer::address_of(&a));
        MyToken::init(&new_account);
        // Create 'Balance<TokenType>' resource under sender account, and init with zero

        let market_cap = Token::market_cap<MyToken>();
        assert(market_cap == 0, 8001);
        assert(Token::is_registered_in<MyToken>(Signer::address_of(&new_account)), 8002);

        let coin = Token::mint<MyToken>(&new_account, 1000000);
        Account::deposit_to_self<MyToken>(&new_account, coin);

        Account::release_genesis_signer(new_account);
    }
}