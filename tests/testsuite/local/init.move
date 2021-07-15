// Copyright (c) The Starcoin Core Contributors
// SPDX-License-Identifier: Apache-2.0
// check: EXECUTED

script {
    //use 0x1::Account;
//    use 0x1::Token;
    //use 0x1::Signer;
    //use 0x1::MyToken::{MyToken, Self};
    use 0x1::Debug;
    use 0xbd7e8be8fae9f60f2f5136433e36a091::Bot::Bot;
    use 0xbd7e8be8fae9f60f2f5136433e36a091::Ddd::Ddd;
    use 0xbd7e8be8fae9f60f2f5136433e36a091::TokenSwap;

    fun main(_a: signer) {
        let ret = TokenSwap::compare_token<Ddd, Bot>();
        Debug::print<u8>(&ret);
        assert(ret == 1, 10000);
    }
}