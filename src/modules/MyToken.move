// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

address 0x1 {
module MyToken {
    use 0x1::Token;
    use 0x1::Account;

    struct MyToken has copy, drop, store { }

    public fun init(account: &signer) {
        //assert(Signer::address_of(account) == 0x1, 8000);
        Token::register_token<MyToken>(
            account,
            3,
        );
        Account::do_accept_token<MyToken>(account);
    }
}
}