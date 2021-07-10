// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

script {
    //use 0x1::Account;
//    use 0x1::Token;
    //use 0x1::Signer;
    //use 0x1::MyToken::{MyToken, Self};
    use 0x1::Debug;
    use 0x07fa08a855753f0ff7292fdcbe871216::Bot::Bot;
    use 0x07fa08a855753f0ff7292fdcbe871216::Ddd::Ddd;
    use 0x07fa08a855753f0ff7292fdcbe871216::TokenSwap;

    fun main(_a: signer) {
        let ret = TokenSwap::compare_token<Ddd, Bot>();
        Debug::print<u8>(&ret);
        assert(ret == 1, 10000);
    }
}