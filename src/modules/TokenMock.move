// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED
address 0x1 {
module TokenMock {
    use 0x1::Token;
    use 0x1::Account;

    //
    /// Mint mock token to signer
    ///
    public fun mint_token<T: store>(account: &signer, amount: u128): Token::Token<T> {
        Token::register_token<T>(account, 3);
        let cap = Token::market_cap<T>();
        assert(cap == 0, 8001);
        Account::do_accept_token<T>(account);
        Token::mint<T>(account, amount)
    }
}

}
