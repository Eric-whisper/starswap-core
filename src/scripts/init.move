// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

//address 0x1 {
//module Token1 {
//    struct Token1 has store {}
//}
//}

script {
    use 0x1::Signer;
    use 0x1::Debug;
//    use 0x1::Account;
//    use 0x1::Token;

    fun init(account: signer) {
        assert(Signer::address_of(&account) == 0x1, 8000);
        Debug::print(&Signer::address_of(&account));

//        Token::register_token<Token1::Token1>(
//            signer,
//            1000000, // scaling_factor = 10^6
//            1000,    // fractional_part = 10^3
//        );
//        let token = Token::mint<0x1::Token1::Token1>(&signer, 10000 * 10000 * 2);
//        Account::deposit(&signer, token);
//        assert(Account::balance<0x1::Token1::Token1>({0x1}) == 10000 * 10000 * 2, 42);
    }
}